import os
import shutil
import uuid
import logging
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from services.ocr_service import OCRService
from services.gemini_service import GeminiService
from services.confidence_service import ConfidenceService
from models.response_models import (
    OCRExtractionResponse,
    ParseTextRequest,
    ParseTextResponse,
    GeminiParseResponse,
    MedicalDataExtraction,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("main")

app = FastAPI(
    title="Asha Sathi — OCR & Medical Parsing Service",
    version="2.0.0",
    description="PaddleOCR extraction + Gemini 2.5 Flash medical data parsing",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ── Singleton service instances ───────────────────────────────────────────────
ocr_service = OCRService()
gemini_service = GeminiService()
confidence_service = ConfidenceService()


# ── Startup ───────────────────────────────────────────────────────────────────

@app.on_event("startup")
async def startup_event():
    """
    Warm up both singletons at startup:
    - PaddleOCR loads its models into memory
    - GeminiService loads and caches prompt files
    """
    logger.info("Starting up OCR & Gemini services...")
    ocr_service.initialize()
    gemini_service.initialize()
    logger.info("All services ready.")


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and monitoring."""
    ocr_ready = ocr_service.ocr is not None
    gemini_ready = gemini_service._initialized
    return {
        "status": "healthy" if (ocr_ready and gemini_ready) else "initializing",
        "ocr_model_loaded": ocr_ready,
        "gemini_ready": gemini_ready,
        "version": "2.0.0",
    }


# ── OCR Endpoint ──────────────────────────────────────────────────────────────

@app.post("/extract-text", response_model=OCRExtractionResponse)
async def extract_text(file: UploadFile = File(...)):
    """
    Receive an image file, run PaddleOCR, return extracted text with
    per-line confidence scores and an aggregate document confidence score.

    Supported formats: jpg, jpeg, png, bmp, webp
    Target processing time: < 3 seconds for standard prescriptions
    """
    allowed_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    _, ext = os.path.splitext((file.filename or "").lower())
    if ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image format '{ext}'. Allowed: {allowed_extensions}",
        )

    temp_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}{ext}")
    try:
        with open(temp_path, "wb") as buf:
            shutil.copyfileobj(file.file, buf)

        result = ocr_service.extract_text(temp_path)

        if os.path.exists(temp_path):
            os.remove(temp_path)

        if not result["success"]:
            raise HTTPException(
                status_code=500,
                detail=result.get("error", "OCR processing failed"),
            )

        # Annotate per-line confidence levels
        annotated_segments = confidence_service.annotate_segments(result["segments"])
        aggregate_confidence = confidence_service.aggregate_score(annotated_segments)

        return OCRExtractionResponse(
            success=True,
            raw_text=result["raw_text"],
            confidence=aggregate_confidence,
            segments=annotated_segments,
            processing_time_ms=result["processing_time_ms"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"OCR endpoint error: {e}", exc_info=True)
        if os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except Exception:
                pass
        raise HTTPException(status_code=500, detail=f"Internal service error: {e}")


# ── Gemini Parse Endpoint ─────────────────────────────────────────────────────

@app.post("/parse-text", response_model=ParseTextResponse)
async def parse_text(request: ParseTextRequest):
    """
    Accept OCR-extracted text, send to Gemini 2.5 Flash, and return
    a structured medical JSON object.

    This endpoint replaces the previous Ollama/Llama 3.1 integration.
    """
    if not request.raw_text.strip():
        raise HTTPException(status_code=400, detail="OCR text cannot be empty.")

    try:
        extracted = await gemini_service.extract_medical_data(request.raw_text)

        data = MedicalDataExtraction(
            diagnosis=extracted.get("diagnosis"),
            follow_up_date=extracted.get("follow_up_date"),
            medicines=extracted.get("medicines", []),
            lab_tests=extracted.get("lab_tests", []),
            notes=extracted.get("notes"),
        )

        return ParseTextResponse(success=True, data=data)

    except RuntimeError as e:
        # Gemini API errors (key missing, rate limit exhausted, etc.)
        logger.error(f"Gemini service error: {e}")
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Parse endpoint error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Parser error: {e}")


# ── Gemini Full Pipeline Endpoint (OCR + Parse + Summary) ─────────────────────

@app.post("/parse-and-summarize", response_model=GeminiParseResponse)
async def parse_and_summarize(request: ParseTextRequest):
    """
    Extended endpoint: extract medical data AND generate an AI clinical summary
    in a single call. Used by Spring Boot's async processing pipeline.
    """
    if not request.raw_text.strip():
        raise HTTPException(status_code=400, detail="OCR text cannot be empty.")

    try:
        extracted = await gemini_service.extract_medical_data(request.raw_text)
        summary = await gemini_service.generate_summary(extracted)

        data = MedicalDataExtraction(
            diagnosis=extracted.get("diagnosis"),
            follow_up_date=extracted.get("follow_up_date"),
            medicines=extracted.get("medicines", []),
            lab_tests=extracted.get("lab_tests", []),
            notes=extracted.get("notes"),
        )

        return GeminiParseResponse(success=True, data=data, summary=summary)

    except RuntimeError as e:
        logger.error(f"Gemini service error: {e}")
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Parse-and-summarize error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Pipeline error: {e}")
