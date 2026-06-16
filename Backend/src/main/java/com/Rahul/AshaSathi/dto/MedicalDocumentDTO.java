package com.Rahul.AshaSathi.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

/**
 * Request/Response DTOs for the Medical Vision Agent.
 * Nested static classes keep everything organized in one file.
 */
public class MedicalDocumentDTO {

    // ─── Request: Upload a new document ──────────────────────────────────────
    @Data
    public static class UploadRequest {
        private Long patientId;
    }

    // ─── Inner DTOs used in responses ────────────────────────────────────────
    @Data
    public static class MedicineDTO {
        private Long id;
        private String medicineName;
        private String dosage;
        private String frequency;
        private String duration;
        private boolean verified;
        private String matchedDrugName;
        private Integer matchScore;
    }

    @Data
    public static class LabResultDTO {
        private Long id;
        private String testName;
        private String value;
        private String unit;
        private String severity;
        private String referenceRange;
    }

    // ─── Full document response returned to Flutter ───────────────────────────
    @Data
    public static class DocumentResponse {
        private Long id;
        private Long patientId;
        private String imagePath;
        private String rawText;
        private String diagnosis;
        private String followUpDate;
        private String aiSummary;
        private String processingStatus;
        private Double ocrConfidence;
        private String createdAt;
        private List<MedicineDTO> medicines;
        private List<LabResultDTO> labResults;
    }

    // ─── Used internally by processing service ────────────────────────────────
    @Data
    public static class OcrExtractResponse {
        private boolean success;

        @JsonProperty("raw_text")
        private String rawText;

        private List<SegmentDTO> segments;

        @JsonProperty("processing_time_ms")
        private double processingTimeMs;

        private String error;

        @Data
        public static class SegmentDTO {
            private String text;
            private double confidence;
        }
    }

    @Data
    public static class ParsedMedicalData {
        private String diagnosis;
        private String followUpDate;
        private List<ExtractedMedicine> medicines;
        private List<ExtractedLabTest> labTests;
        private String notes;

        @Data
        public static class ExtractedMedicine {
            private String name;
            private String dosage;
            private String frequency;
            private String duration;
        }

        @Data
        public static class ExtractedLabTest {
            private String testName;
            private String value;
            private String unit;
            private String referenceRange;
        }
    }

    // ─── Gemini Parse + Summarize response (from Python service) ────────────
    @Data
    public static class GeminiParseResponse {
        private boolean success;
        private GeminiMedicalData data;
        private String summary;
        private String error;
    }

    @Data
    public static class GeminiMedicalData {
        private String diagnosis;

        @JsonProperty("follow_up_date")
        private String followUpDate;

        private List<GeminiMedicine> medicines;

        @JsonProperty("lab_tests")
        private List<GeminiLabTest> labTests;

        private String notes;

        @Data
        public static class GeminiMedicine {
            private String name;
            private String dosage;
            private String frequency;
            private String duration;
        }

        @Data
        public static class GeminiLabTest {
            @JsonProperty("test_name")
            private String testName;
            private String value;
            private String unit;
            @JsonProperty("reference_range")
            private String referenceRange;
        }
    }

    // ─── Gemini Parse request body ───────────────────────────────────────────
    @Data
    public static class GeminiParseRequest {
        @JsonProperty("raw_text")
        private String rawText;
    }

    // ─── Asynchronous processing result ──────────────────────────────────────
    @Data
    public static class ProcessingStatusResponse {
        private Long documentId;
        private String status;
        private String message;
    }
}
