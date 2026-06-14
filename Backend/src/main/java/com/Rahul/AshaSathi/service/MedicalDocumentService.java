package com.Rahul.AshaSathi.service;

import com.Rahul.AshaSathi.dto.MedicalDocumentDTO;
import com.Rahul.AshaSathi.entity.*;
import com.Rahul.AshaSathi.repository.MedicalDocumentRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
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
    private final OllamaClient ollamaClient;
    private final ValidationService validationService;

    @Value("${app.ocr.service-url:http://localhost:8000}")
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

            // Step 1: OCR Extraction
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

            // Step 2: LLM Extraction
            log.info("Step 2: Calling Ollama for structured extraction, document {}", documentId);
            String rawLlmJson = ollamaClient.extractMedicalData(ocrResult.getRawText());
            MedicalDocumentDTO.ParsedMedicalData parsed = parseLlmResponse(rawLlmJson);

            doc.setDiagnosis(parsed.getDiagnosis());
            doc.setFollowUpDate(parsed.getFollowUpDate());

            // Step 3: Validate medicines
            log.info("Step 3: Validating medicines for document {}", documentId);
            List<Medicine> medicines = buildValidatedMedicines(doc, parsed.getMedicines());
            doc.getMedicines().clear();
            doc.getMedicines().addAll(medicines);

            // Step 4: Validate lab results
            log.info("Step 4: Validating lab results for document {}", documentId);
            List<LabResult> labResults = buildValidatedLabResults(doc, parsed.getLabTests());
            doc.getLabResults().clear();
            doc.getLabResults().addAll(labResults);

            // Step 5: Generate AI clinical summary
            log.info("Step 5: Generating clinical summary for document {}", documentId);
            String summary = generateSummary(parsed, labResults);
            doc.setAiSummary(summary);

            // Step 6: Mark complete
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

    public MedicalDocumentDTO.DocumentResponse getDocument(Long id) {
        MedicalDocument doc = documentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Document not found: " + id));
        return toDocumentResponse(doc);
    }

    public List<MedicalDocumentDTO.DocumentResponse> getDocumentsByPatient(Long patientId) {
        return documentRepository.findByPatientId(patientId)
                .stream().map(this::toDocumentResponse).collect(Collectors.toList());
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

    // ─── Parse LLM JSON Response ─────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private MedicalDocumentDTO.ParsedMedicalData parseLlmResponse(String json) {
        MedicalDocumentDTO.ParsedMedicalData data = new MedicalDocumentDTO.ParsedMedicalData();
        try {
            // Strip markdown code fences if present
            String cleaned = json.trim()
                    .replaceAll("(?s)^```json\\s*", "")
                    .replaceAll("(?s)```\\s*$", "")
                    .trim();

            // Extract from first '{' to last '}'
            int start = cleaned.indexOf('{');
            int end = cleaned.lastIndexOf('}');
            if (start >= 0 && end > start) {
                cleaned = cleaned.substring(start, end + 1);
            }

            // Remove trailing commas before ] or }
            cleaned = cleaned.replaceAll(",\\s*([}\\]])", "$1");

            Map<String, Object> map = objectMapper.readValue(cleaned, Map.class);

            data.setDiagnosis((String) map.get("diagnosis"));
            data.setFollowUpDate((String) map.get("follow_up_date"));
            data.setNotes(map.get("notes") != null ? map.get("notes").toString() : "");

            // Medicines
            List<MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine> medicines = new ArrayList<>();
            if (map.get("medicines") instanceof List<?> rawMeds) {
                for (Object rawMed : rawMeds) {
                    if (rawMed instanceof Map<?, ?> m) {
                        MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine med =
                                new MedicalDocumentDTO.ParsedMedicalData.ExtractedMedicine();
                        med.setName(safeStr(m.get("name")));
                        med.setDosage(safeStr(m.get("dosage")));
                        med.setFrequency(safeStr(m.get("frequency")));
                        med.setDuration(safeStr(m.get("duration")));
                        medicines.add(med);
                    }
                }
            }
            data.setMedicines(medicines);

            // Lab tests
            List<MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest> labs = new ArrayList<>();
            if (map.get("lab_tests") instanceof List<?> rawLabs) {
                for (Object rawLab : rawLabs) {
                    if (rawLab instanceof Map<?, ?> l) {
                        MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest lab =
                                new MedicalDocumentDTO.ParsedMedicalData.ExtractedLabTest();
                        lab.setTestName(safeStr(l.get("test_name")));
                        lab.setValue(safeStr(l.get("value")));
                        lab.setUnit(safeStr(l.get("unit")));
                        lab.setReferenceRange(safeStr(l.get("reference_range")));
                        labs.add(lab);
                    }
                }
            }
            data.setLabTests(labs);

        } catch (Exception e) {
            log.error("Failed to parse LLM JSON response: {} | Raw: {}", e.getMessage(), json);
        }
        return data;
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

    // ─── Generate Clinical Summary ─────────────────────────────────────────────

    private String generateSummary(MedicalDocumentDTO.ParsedMedicalData parsed, List<LabResult> labResults) {
        try {
            String medStr = parsed.getMedicines() == null ? "None" :
                    parsed.getMedicines().stream()
                            .map(m -> m.getName() + " " + m.getDosage() + " " + m.getFrequency())
                            .collect(Collectors.joining(", "));

            String abnormalStr = labResults.stream()
                    .filter(l -> l.getSeverity() != LabResult.Severity.NORMAL)
                    .map(l -> l.getTestName() + ": " + l.getValue() + " " + l.getUnit()
                            + " (" + l.getSeverity() + ")")
                    .collect(Collectors.joining(", "));
            if (abnormalStr.isBlank()) abnormalStr = "None";

            return ollamaClient.generateClinicalSummary(
                    parsed.getDiagnosis() != null ? parsed.getDiagnosis() : "Unknown",
                    medStr,
                    abnormalStr,
                    parsed.getFollowUpDate() != null ? parsed.getFollowUpDate() : "Not specified"
            );
        } catch (Exception e) {
            log.warn("Summary generation failed: {}", e.getMessage());
            return "AI summary unavailable.";
        }
    }

    // ─── Mapper ──────────────────────────────────────────────────────────────

    public MedicalDocumentDTO.DocumentResponse toDocumentResponse(MedicalDocument doc) {
        MedicalDocumentDTO.DocumentResponse resp = new MedicalDocumentDTO.DocumentResponse();
        resp.setId(doc.getId());
        resp.setPatientId(doc.getPatientId());
        resp.setImagePath(doc.getImagePath());
        resp.setRawText(doc.getRawText());
        resp.setDiagnosis(doc.getDiagnosis());
        resp.setFollowUpDate(doc.getFollowUpDate());
        resp.setAiSummary(doc.getAiSummary());
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

    private String safeStr(Object val) {
        return val != null ? val.toString() : "";
    }
}
