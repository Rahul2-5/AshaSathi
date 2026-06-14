package com.Rahul.AshaSathi.Entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Stores individual OCR line segments for audit and debugging.
 * Enables per-line confidence tracing and OCR quality analysis.
 */
@Entity
@Table(name = "ocr_line", indexes = {
    @Index(name = "idx_ocr_line_document", columnList = "document_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OcrLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_id", nullable = false)
    private MedicalDocument document;

    @Column(name = "extracted_text", nullable = false, columnDefinition = "TEXT")
    private String extractedText;

    /** Confidence score 0.0 – 1.0 from PaddleOCR. */
    @Column(name = "confidence", nullable = false)
    private double confidence;

    /** Classified level: HIGH, MEDIUM, REVIEW_REQUIRED. */
    @Column(name = "confidence_level", length = 20)
    private String confidenceLevel;

    /** Sequential position of this line in the document. */
    @Column(name = "line_order")
    private int lineOrder;
}
