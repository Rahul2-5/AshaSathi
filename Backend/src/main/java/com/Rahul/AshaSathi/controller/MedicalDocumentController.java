package com.Rahul.AshaSathi.controller;

import com.Rahul.AshaSathi.dto.MedicalDocumentDTO;
import com.Rahul.AshaSathi.service.MedicalDocumentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * MedicalDocumentController — Phase 8
 *
 * Endpoints:
 *   POST   /api/medical-documents/upload       → Upload image, create PENDING record
 *   POST   /api/medical-documents/{id}/process → Trigger async processing pipeline
 *   GET    /api/medical-documents/{id}          → Get document with results
 *   GET    /api/medical-documents/patient/{pid} → Get all docs for a patient
 */
@RestController
@RequestMapping("/api/medical-documents")
@Slf4j
@RequiredArgsConstructor
public class MedicalDocumentController {

    private final MedicalDocumentService medicalDocumentService;

    /**
     * POST /api/medical-documents/upload
     * Accepts a multipart image, saves it, creates a PENDING record and returns the document ID.
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MedicalDocumentDTO.DocumentResponse> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "patientId", required = false) Long patientId) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        // Validate file type
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE).build();
        }

        // File size guard (max 10MB)
        if (file.getSize() > 10 * 1024 * 1024) {
            return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).build();
        }

        try {
            MedicalDocumentDTO.DocumentResponse response =
                    medicalDocumentService.uploadDocument(file, patientId);
            log.info("Document uploaded successfully: id={}", response.getId());
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            log.error("Upload failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/medical-documents/{id}/process
     * Triggers the async OCR → LLM → Validation → Summary pipeline for a document.
     */
    @PostMapping("/{id}/process")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MedicalDocumentDTO.ProcessingStatusResponse> processDocument(
            @PathVariable Long id) {
        try {
            // Fire and forget — returns immediately with PROCESSING status
            medicalDocumentService.processDocumentAsync(id);

            MedicalDocumentDTO.ProcessingStatusResponse resp = new MedicalDocumentDTO.ProcessingStatusResponse();
            resp.setDocumentId(id);
            resp.setStatus("PROCESSING");
            resp.setMessage("Document processing started. Poll GET /api/medical-documents/" + id + " for results.");
            return ResponseEntity.accepted().body(resp);
        } catch (Exception e) {
            log.error("Failed to trigger processing for document {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/medical-documents/{id}
     * Returns the full document with medicines, lab results, AI summary and processing status.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MedicalDocumentDTO.DocumentResponse> getDocument(@PathVariable Long id) {
        try {
            MedicalDocumentDTO.DocumentResponse response = medicalDocumentService.getDocument(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            log.warn("Document not found: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * GET /api/medical-documents/patient/{patientId}
     * Returns all documents for a given patient.
     */
    @GetMapping("/patient/{patientId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<MedicalDocumentDTO.DocumentResponse>> getDocumentsByPatient(
            @PathVariable Long patientId) {
        List<MedicalDocumentDTO.DocumentResponse> docs =
                medicalDocumentService.getDocumentsByPatient(patientId);
        return ResponseEntity.ok(docs);
    }
}
