package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.DTO.MedicalDocumentResponse;
import com.Rahul.AshaSathi.DTO.MedicalDocumentUploadResponse;
import com.Rahul.AshaSathi.Entity.MedicalDocument;
import com.Rahul.AshaSathi.Repository.MedicalDocumentRepository;
import com.Rahul.AshaSathi.Services.MedicalDocumentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * REST controller for the Medical Vision Agent API.
 *
 * Endpoints:
 *   POST /api/medical-documents/upload    — Upload image → create DB record
 *   POST /api/medical-documents/{id}/process — Trigger async AI pipeline
 *   GET  /api/medical-documents/{id}      — Poll for processing result
 *   GET  /api/medical-documents/patient/{patientId} — List patient documents
 *
 * The Flutter client flow:
 *   1. POST upload → get {id}
 *   2. POST process → triggers async pipeline
 *   3. GET {id} every 3s → poll until processingStatus == COMPLETED
 */
@Slf4j
@RestController
@RequestMapping("/api/medical-documents")
@RequiredArgsConstructor
public class MedicalDocumentController {

    private final MedicalDocumentRepository docRepo;
    private final MedicalDocumentService    docService;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    // ── POST /api/medical-documents/upload ────────────────────────────────────

    /**
     * Accept a multipart image upload, save it to disk, create the DB record
     * with status=PENDING, and return the document ID.
     *
     * Returns 201 Created with {id, processingStatus, message}.
     */
    @PostMapping("/upload")
    public ResponseEntity<MedicalDocumentUploadResponse> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "patientId", required = false) Long patientId) {

        log.info("Received document upload: file='{}', size={}bytes, patientId={}",
            file.getOriginalFilename(), file.getSize(), patientId);

        // Validate file
        if (file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Uploaded file is empty.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Only image files are accepted. Received: " + contentType);
        }

        // Save image to disk
        String imagePath = saveUploadedFile(file);

        // Create DB record
        MedicalDocument doc = MedicalDocument.builder()
            .patientId(patientId)
            .imagePath(imagePath)
            .processingStatus(MedicalDocument.ProcessingStatus.PENDING)
            .build();
        doc = docRepo.save(doc);

        log.info("Created MedicalDocument id={} for patientId={}, imagePath={}",
            doc.getId(), patientId, imagePath);

        // Immediately trigger OCR extraction and store raw text + confidence
        // (OCR is fast — blocking here is acceptable and saves a round-trip)
        try {
            byte[] imageBytes = file.getBytes();
            String filename   = file.getOriginalFilename() != null
                ? file.getOriginalFilename() : "upload.jpg";

            Map<String, Object> ocrResult =
                docService.extractTextFromBytes(imageBytes, filename);

            String rawText    = (String) ocrResult.getOrDefault("raw_text", "");
            double confidence = toDouble(ocrResult.getOrDefault("confidence", 0.0));
            List<Map<String, Object>> segments =
                (List<Map<String, Object>>) ocrResult.getOrDefault("segments", List.of());

            doc.setRawText(rawText);
            doc.setConfidenceScore(confidence);
            doc = docRepo.save(doc);

            // Persist OCR line segments
            docService.persistOcrLines(doc, segments);

            log.info("OCR complete for doc {}: {} chars, confidence={}", doc.getId(), rawText.length(), confidence);
        } catch (Exception e) {
            log.warn("OCR pre-extraction failed for doc {}: {}", doc.getId(), e.getMessage());
            // Non-fatal — pipeline will retry via /process
        }

        return ResponseEntity.status(HttpStatus.CREATED)
            .body(new MedicalDocumentUploadResponse(
                doc.getId(),
                doc.getProcessingStatus().name(),
                "Document uploaded successfully. Call /process to start AI analysis."
            ));
    }

    // ── POST /api/medical-documents/{id}/process ─────────────────────────────

    /**
     * Trigger the asynchronous Gemini + Validation pipeline for a document.
     * Returns immediately with 202 Accepted.
     */
    @PostMapping("/{id}/process")
    public ResponseEntity<Map<String, Object>> processDocument(@PathVariable Long id) {
        MedicalDocument doc = findDocOrThrow(id);

        if (doc.getProcessingStatus() == MedicalDocument.ProcessingStatus.PROCESSING) {
            return ResponseEntity.accepted()
                .body(Map.of("message", "Document is already being processed.", "id", id));
        }

        if (doc.getProcessingStatus() == MedicalDocument.ProcessingStatus.COMPLETED) {
            return ResponseEntity.ok(
                Map.of("message", "Document already processed.", "id", id));
        }

        log.info("Triggering async processing pipeline for doc {}", id);
        docService.processDocument(id, doc.getImagePath());

        return ResponseEntity.accepted()
            .body(Map.of(
                "message", "Processing started. Poll GET /api/medical-documents/" + id,
                "id", id
            ));
    }

    // ── GET /api/medical-documents/{id} ──────────────────────────────────────

    /**
     * Poll endpoint used by Flutter every 3 seconds.
     * Returns the full document with processingStatus, medicines, lab results, summary.
     */
    @GetMapping("/{id}")
    public ResponseEntity<MedicalDocumentResponse> getDocument(@PathVariable Long id) {
        MedicalDocument doc = findDocOrThrow(id);

        // Force-load lazy collections
        doc.getMedicines().size();
        doc.getLabResults().size();

        return ResponseEntity.ok(MedicalDocumentResponse.from(doc));
    }

    // ── GET /api/medical-documents/patient/{patientId} ────────────────────────

    /**
     * List all medical documents for a specific patient, newest first.
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<MedicalDocumentResponse>> getPatientDocuments(
            @PathVariable Long patientId) {
        List<MedicalDocument> docs =
            docRepo.findByPatientIdOrderByCreatedAtDesc(patientId);

        List<MedicalDocumentResponse> responses = docs.stream()
            .map(doc -> {
                doc.getMedicines().size();
                doc.getLabResults().size();
                return MedicalDocumentResponse.from(doc);
            })
            .toList();

        return ResponseEntity.ok(responses);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private MedicalDocument findDocOrThrow(Long id) {
        return docRepo.findById(id)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Medical document not found: " + id));
    }

    private String saveUploadedFile(MultipartFile file) {
        try {
            // Resolve to an absolute path so the destination never depends on the
            // process working directory (important on Heroku's ephemeral dyno).
            Path dir = Paths.get(uploadDir).toAbsolutePath();
            Files.createDirectories(dir);

            String ext = "";
            String original = file.getOriginalFilename();
            if (original != null && original.contains(".")) {
                ext = original.substring(original.lastIndexOf('.'));
            }
            String filename = UUID.randomUUID() + ext;
            Path target = dir.resolve(filename);
            // Write via the input stream rather than transferTo(File): transferTo can
            // throw IllegalStateException (a RuntimeException) when the temp file has
            // already been moved, which would otherwise escape uncaught.
            try (var in = file.getInputStream()) {
                Files.copy(in, target, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
            return target.toString();
        } catch (Exception e) {
            log.error("Failed to save uploaded file '{}': {}",
                file.getOriginalFilename(), e.toString(), e);
            throw new ResponseStatusException(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Failed to save uploaded file: " + e.getMessage()
            );
        }
    }

    private double toDouble(Object value) {
        if (value instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(value.toString()); }
        catch (Exception e) { return 0.0; }
    }
}
