package com.Rahul.AshaSathi.DTO;

import lombok.Data;

/**
 * Response returned immediately after a successful document upload.
 * The Flutter client uses the id to trigger processing and then poll for results.
 */
@Data
public class MedicalDocumentUploadResponse {
    private Long id;
    private String processingStatus;
    private String message;

    public MedicalDocumentUploadResponse(Long id, String status, String message) {
        this.id = id;
        this.processingStatus = status;
        this.message = message;
    }
}
