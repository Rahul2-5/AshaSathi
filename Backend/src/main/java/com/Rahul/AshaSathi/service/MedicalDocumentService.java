package com.Rahul.AshaSathi.service;

import com.Rahul.AshaSathi.dto.MedicalDocumentDTO;
import com.Rahul.AshaSathi.entity.*;
import com.Rahul.AshaSathi.repository.FamilyPatientRepository;
import com.Rahul.AshaSathi.repository.MedicalDocumentRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * MedicalDocumentService — Phase 8 Orchestrator
 *
 * Full pipeline:
 *  1. Save image to disk
 *  2. Call Python OCR service → extract raw text + confidence
 *  3. Call OllamaClient → extract structured JSON
 *  4. Parse & validate medicines (Levenshtein fuzzy match)
 *  5. Validate lab results (reference range severity)
 *  6. Generate AI clinical summary
 *  7. Persist everything to PostgreSQL
 *  8. Return DocumentResponse to controller
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class MedicalDocumentService {

    private final MedicalDocumentRepository documentRepository;
    private final FamilyPatientRepository familyPatientRepository;
    private final ValidationService validationService;

    @Value("${app.ocr.service-url:http://localhost:8001}")
    private String ocrServiceUrl;

    @Value("${app.upload.dir:uploads/medical}")
    private String uploadDir;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // ─── Upload & Trigger Processing ─────────────────────────────────────────

    /**
     * Saves the uploaded image and creates a PENDING document record.
     * Processing is triggered asynchronously.
     */
    public MedicalDocumentDTO.DocumentResponse uploadDocument(MultipartFile file, Long patientId) throws IOException {
        // Save image to disk
        Path uploadPath = Paths.get(uploadDir);
        Files.createDirectories(uploadPath);
        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path filePath = uploadPath.resolve(filename);
        Files.copy(file.getInputStream(), filePath);

        // Create PENDING record
        MedicalDocument doc = new MedicalDocument();
        doc.setPatientId(patientId);
        doc.setImagePath(filePath.toString());
        doc.setProcessingStatus(MedicalDocument.ProcessingStatus.PENDING);
        MedicalDocument saved = documentRepository.save(doc);

        log.info("Document {} created with PENDING status for patient {}", saved.getId(), patientId);
        return toDocumentResponse(saved);
    }

    /**
     * Async processing pipeline. Runs in a background thread.
     * Updates the document status throughout processing.
     */
    @Async
    public void processDocumentAsync(Long documentId) {
        MedicalDocument doc = documentRepository.findById(documentId).orElse(null);
        if (doc == null) {
            log.error("Document {} not found for processing", documentId);
            return;
        }

        try {
            doc.setProcessingStatus(MedicalDocument.ProcessingStatus.PROCESSING);
            documentRepository.save(doc);

            // Step 1: OCR Extraction (Python PaddleOCR service)
            log.info("Step 1: Calling OCR service for document {}", documentId);
            MedicalDocumentDTO.OcrExtractResponse ocrResult = callOcrService(doc.getImagePath());

            if (!ocrResult.isSuccess() || ocrResult.getRawText() == null || ocrResult.getRawText().isBlank()) {
                throw new RuntimeException("OCR returned empty text: " + ocrResult.getError());
            }

            doc.setRawText(ocrResult.getRawText());

            // Average confidence from all segments
            if (ocrResult.getSegments() != null && !ocrResult.getSegments().isEmpty()) {
                double avgConf = ocrResult.getSegments().stream()
                        .mapToDouble(MedicalDocumentDTO.OcrExtractResponse.SegmentDTO::getConfidence)
                        .average().orElse(0.0);
                doc.setOcrConfidence(avgConf);
            }

            // Step 2: Gemini extraction + summary (Python Gemini service)
            // Fetch patient age/gender to give Gemini clinical context
            Integer patientAge = null;
            String patientGender = null;
            if (doc.getPatientId() != null) {
                var patientOpt = familyPatientRepository.findById(doc.getPatientId());
                if (patientOpt.isPresent()) {
                    patientAge = patientOpt.get().getAge();
                    patientGender = patientOpt.get().getGender();
                }
            }
            log.info("Step 2: Calling Gemini service for extraction + summary, document {}", documentId);
            MedicalDocumentDTO.GeminiParseResponse geminiResult =
                    callGeminiParseAndSummarize(ocrResult.getRawText(), patientAge, patientGender);

            if (!geminiResult.isSuccess() || geminiResult.getData() == null) {
                throw new RuntimeException("Gemini parse failed: " +
                        (geminiResult.getError() != null ? geminiResult.getError() : "No data returned"));
            }

            MedicalDocumentDTO.GeminiMedicalData geminiData = geminiResult.getData();
            doc.setDiagnosis(geminiData.getDiagnosis());
            doc.setFollowUpDate(geminiData.getFollowUpDate());
            doc.setDocumentType(geminiData.getDocumentType());
            doc.setDoctorName(geminiData.getDoctorName());
            doc.setHospitalName(geminiData.getHospitalName());

            // Convert Gemini medicines to ParsedMedicalData format for validation
            MedicalDocumentDTO.ParsedMedicalData parsed = convertGeminiToParsed(geminiData);

            // Step 3: Validate medicines
            log.info("Step 3: Validating medicines for document {}", documentId);
            List<Medicine> medicines = buildValidatedMedicines(doc, parsed.getMedicines());
            doc.setMedicines(medicines);

            // Step 4: Validate lab results
            log.info("Step 4: Validating lab results for document {}", documentId);
            List<LabResult> labResults = buildValidatedLabResults(doc, parsed.getLabTests());
            doc.setLabResults(labResults);

            // Step 5: Persist AI summary and ASHA actions.
            // Use a direct @Modifying UPDATE (belt) AND set on the detached entity (suspenders)
            // so the final merge in Step 6 cannot overwrite the columns with null.
            String summary = geminiResult.getSummary();
            String ashaActions = geminiResult.getAshaActions();
            log.info("Step 5: Persisting AI summary ({} chars) and ASHA actions ({} chars) for document {}",
                    summary != null ? summary.length() : 0,
                    ashaActions != null ? ashaActions.length() : 0,
                    documentId);
            documentRepository.updateSummary(documentId, summary, ashaActions);
            doc.setAiSummary(summary);
            doc.setAshaActions(ashaActions);

            // Step 6: Mark complete — merge also carries aiSummary so it is not overwritten
            doc.setProcessingStatus(MedicalDocument.ProcessingStatus.COMPLETED);
            documentRepository.save(doc);
            log.info("Document {} processing COMPLETED successfully", documentId);

        } catch (Exception e) {
            log.error("Document {} processing FAILED: {}", documentId, e.getMessage(), e);
            doc.setProcessingStatus(MedicalDocument.ProcessingStatus.FAILED);
            documentRepository.save(doc);
        }
    }

    // ─── Get Document ─────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public MedicalDocumentDTO.DocumentResponse getDocument(Long id) {
        MedicalDocument doc = documentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Document not found: " + id));
        return toDocumentResponse(doc);
    }

    @Transactional(readOnly = true)
    public List<MedicalDocumentDTO.DocumentResponse> getAllDocuments() {
        return documentRepository.findAllByOrderByCreatedAtDesc()
                .stream().map(this::toDocumentResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MedicalDocumentDTO.DocumentResponse> getDocumentsByPatient(Long patientId) {
        return documentRepository.findByPatientId(patientId)
                .stream().map(this::toDocumentResponse).collect(Collectors.toList());
    }

    @Transactional
    public MedicalDocumentDTO.DocumentResponse assignToPatient(Long docId, Long patientId) {
        MedicalDocument doc = documentRepository.findById(docId)
                .orElseThrow(() -> new RuntimeException("Document not found: " + docId));
        doc.setPatientId(patientId);
        documentRepository.save(doc);
        return toDocumentResponse(doc);
    }

    // ─── OCR Service Call ────────────────────────────────────────────────────

    private MedicalDocumentDTO.OcrExtractResponse callOcrService(String imagePath) {
        try {
            String url = ocrServiceUrl + "/extract-text";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new FileSystemResource(new File(imagePath)));

            HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<MedicalDocumentDTO.OcrExtractResponse> response =
                    restTemplate.postForEntity(url, entity, MedicalDocumentDTO.OcrExtractResponse.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            }
            throw new RuntimeException("OCR service returned: " + response.getStatusCode());
        } catch (Exception e) {
            log.error("OCR service call failed: {}", e.getMessage());
            MedicalDocumentDTO.OcrExtractResponse error = new MedicalDocumentDTO.OcrExtractResponse();
            error.setSuccess(false);
            error.setError(e.getMessage());
            return error;
        }
    }

    // ─── Gemini Parse + Summarize call ────────────────────────────────────────

    private MedicalDocumentDTO.GeminiParseResponse callGeminiParseAndSummarize(
            String rawText, Integer patientAge, String patientGender) {
        try {
            String url = ocrServiceUrl + "/parse-and-summarize";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            MedicalDocumentDTO.GeminiParseRequest requestBody = new MedicalDocumentDTO.GeminiParseRequest();
            requestBody.setRawText(rawText);
            requestBody.setPatientAge(patientAge);
            requestBody.setPatientGender(patientGender);

            String jsonBody = objectMapper.writeValueAsString(requestBody);
            HttpEntity<String> entity = new HttpEntity<>(jsonBody, headers);

            log.info("Calling Gemini parse-and-summarize at {}", url);
            ResponseEntity<MedicalDocumentDTO.GeminiParseResponse> response =
                    restTemplate.postForEntity(url, entity, MedicalDocumentDTO.GeminiParseResponse.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.info("Gemini parse-and-summarize succeeded");
                return response.getBody();
            }
            throw new RuntimeException("Gemini service returned: " + response.getStatusCode());
        } catch (Exception e) {
            log.error("Gemini parse-and-summarize call failed: {}", e.getMessage());
            MedicalDocumentDTO.GeminiParseResponse error = new MedicalDocumentDTO.GeminiParseResponse();
            error.setSuccess(false);
            error.setError(e.getMessage());
            return error;
        }
    }

    // ─── Convert Gemini response to ParsedMedicalData for validation ─────────

    private MedicalDocumentDTO.ParsedMedicalData convertGeminiToParsed(MedicalDocumentDTO.GeminiMedicalData gemini) {
        MedicalDocumentDTO.ParsedMedicalData parsed = new MedicalDocumentDTO.ParsedMedicalData();
        parsed.setDiagnosis(gemini.getDiagnosis());
        parsed.setFollowUpDate(gemini.getFollowUpDate());
        parsed.setNotes(gemini.getNotes());

        List<MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine> medicines = new ArrayList<>();
        if (gemini.getMedicines() != null) {
            for (var gm : gemini.getMedicines()) {
                MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine med =
                        new MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine();
                med.setName(gm.getName());
                med.setDosage(gm.getDosage());
                med.setFrequency(gm.getFrequency());
                med.setDuration(gm.getDuration());
                medicines.add(med);
            }
        }
        parsed.setMedicines(medicines);

        List<MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest> labs = new ArrayList<>();
        if (gemini.getLabTests() != null) {
            for (var gl : gemini.getLabTests()) {
                MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest lab =
                        new MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest();
                lab.setTestName(gl.getTestName());
                lab.setValue(gl.getValue());
                lab.setUnit(gl.getUnit());
                lab.setReferenceRange(gl.getReferenceRange());
                labs.add(lab);
            }
        }
        parsed.setLabTests(labs);

        return parsed;
    }

    // ─── Build Validated Medicines ────────────────────────────────────────────

    private List<Medicine> buildValidatedMedicines(
            MedicalDocument doc,
            List<MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine> extracted) {

        List<Medicine> medicines = new ArrayList<>();
        if (extracted == null) return medicines;

        for (var ext : extracted) {
            if (ext.getName() == null || ext.getName().isBlank()) continue;
            ValidationService.DrugValidationResult result = validationService.validateDrug(ext.getName());
            Medicine med = new Medicine();
            med.setDocument(doc);
            med.setMedicineName(ext.getName());
            med.setDosage(ext.getDosage());
            med.setFrequency(ext.getFrequency());
            med.setDuration(ext.getDuration());
            med.setVerified(result.verified());
            med.setMatchedDrugName(result.matchedName());
            med.setMatchScore(result.matchScore());
            medicines.add(med);
        }
        return medicines;
    }

    // ─── Build Validated Lab Results ─────────────────────────────────────────

    private List<LabResult> buildValidatedLabResults(
            MedicalDocument doc,
            List<MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest> extracted) {

        List<LabResult> results = new ArrayList<>();
        if (extracted == null) return results;

        for (var ext : extracted) {
            if (ext.getTestName() == null || ext.getTestName().isBlank()) continue;
            LabResult.Severity severity = validationService.validateLabResult(ext.getTestName(), ext.getValue());
            LabResult lab = new LabResult();
            lab.setDocument(doc);
            lab.setTestName(ext.getTestName());
            lab.setValue(ext.getValue());
            lab.setUnit(ext.getUnit());
            lab.setReferenceRange(ext.getReferenceRange());
            lab.setSeverity(severity);
            results.add(lab);
        }
        return results;
    }

    // ─── Mapper ──────────────────────────────────────────────────────────────

    public MedicalDocumentDTO.DocumentResponse toDocumentResponse(MedicalDocument doc) {
        MedicalDocumentDTO.DocumentResponse resp = new MedicalDocumentDTO.DocumentResponse();
        resp.setId(doc.getId());
        resp.setPatientId(doc.getPatientId());
        resp.setImagePath(doc.getImagePath());
        resp.setRawText(doc.getRawText());
        resp.setDocumentType(doc.getDocumentType());
        resp.setDiagnosis(doc.getDiagnosis());
        resp.setDoctorName(doc.getDoctorName());
        resp.setHospitalName(doc.getHospitalName());
        resp.setFollowUpDate(doc.getFollowUpDate());
        resp.setAiSummary(doc.getAiSummary());
        resp.setAshaActions(doc.getAshaActions());
        resp.setProcessingStatus(doc.getProcessingStatus().name());
        resp.setOcrConfidence(doc.getOcrConfidence());
        resp.setCreatedAt(doc.getCreatedAt() != null ? doc.getCreatedAt().toString() : null);

        resp.setMedicines(doc.getMedicines().stream().map(m -> {
            MedicalDocumentDTO.MedicineDTO dto = new MedicalDocumentDTO.MedicineDTO();
            dto.setId(m.getId());
            dto.setMedicineName(m.getMedicineName());
            dto.setDosage(m.getDosage());
            dto.setFrequency(m.getFrequency());
            dto.setDuration(m.getDuration());
            dto.setVerified(m.isVerified());
            dto.setMatchedDrugName(m.getMatchedDrugName());
            dto.setMatchScore(m.getMatchScore());
            return dto;
        }).collect(Collectors.toList()));

        resp.setLabResults(doc.getLabResults().stream().map(l -> {
            MedicalDocumentDTO.LabResultDTO dto = new MedicalDocumentDTO.LabResultDTO();
            dto.setId(l.getId());
            dto.setTestName(l.getTestName());
            dto.setValue(l.getValue());
            dto.setUnit(l.getUnit());
            dto.setSeverity(l.getSeverity().name());
            dto.setReferenceRange(l.getReferenceRange());
            return dto;
        }).collect(Collectors.toList()));

        return resp;
    }

    // ─── Delete ──────────────────────────────────────────────────────────────

    public void deleteDocument(Long id) {
        MedicalDocument doc = documentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Document not found: " + id));
        // Delete uploaded image file from disk if present
        if (doc.getImagePath() != null) {
            try {
                Files.deleteIfExists(Paths.get(doc.getImagePath()));
            } catch (IOException e) {
                log.warn("Could not delete image file {}: {}", doc.getImagePath(), e.getMessage());
            }
        }
        documentRepository.delete(doc);
        log.info("Deleted medical document id={}", id);
    }

    public void deleteAllDocuments() {
        List<MedicalDocument> all = documentRepository.findAll();
        for (MedicalDocument doc : all) {
            if (doc.getImagePath() != null) {
                try {
                    Files.deleteIfExists(Paths.get(doc.getImagePath()));
                } catch (IOException e) {
                    log.warn("Could not delete image file {}: {}", doc.getImagePath(), e.getMessage());
                }
            }
        }
        documentRepository.deleteAll(all);
        log.info("Deleted all {} medical documents", all.size());
    }

    private String safeStr(Object val) {
        return val != null ? val.toString() : "";
    }
}
