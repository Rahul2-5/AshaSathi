from pydantic import BaseModel
from typing import List, Optional
from enum import Enum


# ── Confidence ───────────────────────────────────────────────────────────────

class ConfidenceLevel(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    REVIEW_REQUIRED = "REVIEW_REQUIRED"


# ── OCR ──────────────────────────────────────────────────────────────────────

class OCRTextSegment(BaseModel):
    text: str
    confidence: float
    confidence_level: Optional[ConfidenceLevel] = None
    box: Optional[List[List[float]]] = None


class OCRExtractionResponse(BaseModel):
    success: bool
    raw_text: str
    confidence: float          # aggregate document-level score
    segments: List[OCRTextSegment]
    processing_time_ms: float
    error: Optional[str] = None


# ── Gemini Medical Extraction ─────────────────────────────────────────────────

class MedicineSchema(BaseModel):
    name: str
    dosage: str
    frequency: str
    duration: str


class LabTestSchema(BaseModel):
    test_name: str
    value: str
    unit: str
    reference_range: str


class MedicalDataExtraction(BaseModel):
    document_type: Optional[str] = None
    diagnosis: Optional[str] = None
    doctor_name: Optional[str] = None
    hospital_name: Optional[str] = None
    follow_up_date: Optional[str] = None
    medicines: List[MedicineSchema] = []
    lab_tests: List[LabTestSchema] = []
    notes: Optional[str] = None


class ParseTextRequest(BaseModel):
    raw_text: str


class GeminiParseAndSummarizeRequest(BaseModel):
    raw_text: str
    patient_age: Optional[int] = None
    patient_gender: Optional[str] = None


class ParseTextResponse(BaseModel):
    success: bool
    data: MedicalDataExtraction
    error: Optional[str] = None


class GeminiParseResponse(BaseModel):
    success: bool
    data: MedicalDataExtraction
    summary: Optional[str] = None
    asha_actions: Optional[str] = None
    error: Optional[str] = None
