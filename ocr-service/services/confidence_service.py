from enum import Enum
from typing import List
import logging

logger = logging.getLogger("confidence_service")


class ConfidenceLevel(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    REVIEW_REQUIRED = "REVIEW_REQUIRED"


class ConfidenceService:
    """
    Classifies OCR confidence at both line-level and document-level.

    Thresholds:
        HIGH            > 0.90
        MEDIUM          0.75 – 0.90
        REVIEW_REQUIRED < 0.75
    """

    HIGH_THRESHOLD = 0.90
    MEDIUM_THRESHOLD = 0.75

    @staticmethod
    def classify(score: float) -> ConfidenceLevel:
        """Classify a single confidence score."""
        if score >= ConfidenceService.HIGH_THRESHOLD:
            return ConfidenceLevel.HIGH
        elif score >= ConfidenceService.MEDIUM_THRESHOLD:
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.REVIEW_REQUIRED

    @staticmethod
    def annotate_segments(segments: List[dict]) -> List[dict]:
        """
        Add a 'confidence_level' key to each segment dict.
        Input  : [{"text": "...", "confidence": 0.97, ...}, ...]
        Output : same list with added 'confidence_level' field
        """
        for seg in segments:
            score = float(seg.get("confidence", 0.0))
            seg["confidence_level"] = ConfidenceService.classify(score).value
        return segments

    @staticmethod
    def aggregate_score(segments: List[dict]) -> float:
        """
        Compute a single document-level confidence score.
        Uses a weighted mean (longer lines weighted by character count).
        Falls back to simple mean if no character-length info is available.
        """
        if not segments:
            return 0.0

        total_weight = 0.0
        weighted_sum = 0.0
        for seg in segments:
            score = float(seg.get("confidence", 0.0))
            text = seg.get("text", "")
            weight = max(len(text), 1)  # weight by text length
            weighted_sum += score * weight
            total_weight += weight

        if total_weight == 0:
            return 0.0

        aggregate = weighted_sum / total_weight
        logger.info(
            f"Aggregate OCR confidence: {aggregate:.4f} "
            f"({ConfidenceService.classify(aggregate).value}) "
            f"over {len(segments)} segments."
        )
        return round(aggregate, 4)
