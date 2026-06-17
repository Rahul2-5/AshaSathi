package com.Rahul.AshaSathi.DTO;

import com.Rahul.AshaSathi.Entity.MedicalDocument;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Full medical document response returned by GET /api/medical-documents/{id}.
 * This is the contract consumed by the Flutter polling loop.
 *
 * Field names match what medical_document_screen.dart expects:
 *   id, processingStatus, diagnosis, followUpDate, aiSummary,
 *   rawText, ocrConfidence, medicines, labResults
 */
@Data
@Builder
public class MedicalDocumentResponse {
    private Long id;
    private Long patientId;          // null = not assigned to any patient (one-off test)
    private String processingStatus;
    private String diagnosis;
    private String followUpDate;      // ISO string for Flutter date display
    private String aiSummary;
    private String rawText;
    private Double ocrConfidence;
    private String errorMessage;
    private LocalDateTime createdAt;
    private List<MedicineResponse> medicines;
    private List<LabResultResponse> labResults;

    // ── Nested DTOs ───────────────────────────────────────────────────────────

    @Data @Builder
    public static class MedicineResponse {
        private Long id;
        private String medicineName;
        private String dosage;
        private String frequency;
        private String duration;
        private boolean verified;
        private String matchedDrugName;
        private Integer matchScore;
    }

    @Data @Builder
    public static class LabResultResponse {
        private Long id;
        private String testName;
        private String value;
        private String unit;
        private String referenceRange;
        private String severity;
    }

    // ── Factory method ────────────────────────────────────────────────────────

    public static MedicalDocumentResponse from(MedicalDocument doc) {
        List<MedicineResponse> medicines = doc.getMedicines().stream()
            .map(m -> MedicineResponse.builder()
                .id(m.getId())
                .medicineName(m.getMedicineName())
                .dosage(m.getDosage())
                .frequency(m.getFrequency())
                .duration(m.getDuration())
                .verified(m.isVerified())
                .matchedDrugName(m.getMatchedDrugName())
                .matchScore(m.getMatchScore())
                .build())
            .toList();

        List<LabResultResponse> labs = doc.getLabResults().stream()
            .map(l -> LabResultResponse.builder()
                .id(l.getId())
                .testName(l.getTestName())
                .value(l.getValue())
                .unit(l.getUnit())
                .referenceRange(l.getReferenceRange())
                .severity(l.getSeverity() != null ? l.getSeverity().name() : "NORMAL")
                .build())
            .toList();

        return MedicalDocumentResponse.builder()
            .id(doc.getId())
            .patientId(doc.getPatientId())
            .processingStatus(doc.getProcessingStatus().name())
            .diagnosis(doc.getDiagnosis())
            .followUpDate(doc.getFollowUpDate() != null ? doc.getFollowUpDate().toString() : null)
            .aiSummary(doc.getAiSummary())
            .rawText(doc.getRawText())
            .ocrConfidence(doc.getConfidenceScore())
            .errorMessage(doc.getErrorMessage())
            .createdAt(doc.getCreatedAt())
            .medicines(medicines)
            .labResults(labs)
            .build();
    }
}
