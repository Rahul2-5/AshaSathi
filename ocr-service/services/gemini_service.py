import os
import json
import re
import logging
import asyncio
from typing import Optional
from pathlib import Path
import httpx

logger = logging.getLogger("gemini_service")

# ── Prompt cache (loaded once at startup) ────────────────────────────────────

_PROMPTS_DIR = Path(__file__).parent / "prompts"
_prompt_cache: dict[str, str] = {}


def _load_prompt(name: str) -> str:
    """Load a prompt file from disk and cache it in memory."""
    if name not in _prompt_cache:
        prompt_path = _PROMPTS_DIR / name
        if not prompt_path.exists():
            raise FileNotFoundError(f"Prompt file not found: {prompt_path}")
        _prompt_cache[name] = prompt_path.read_text(encoding="utf-8")
        logger.info(f"Loaded and cached prompt: {name}")
    return _prompt_cache[name]


# ── Gemini API constants ─────────────────────────────────────────────────────

GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-2.5-flash:generateContent"
)
MAX_RETRIES = 3
TIMEOUT_SECONDS = 45.0
TEMPERATURE = 0.0   # Deterministic output for medical data


# ── Response cleaner ─────────────────────────────────────────────────────────

def _strip_markdown(text: str) -> str:
    """Remove markdown code fences and surrounding whitespace."""
    text = text.strip()
    # Remove ```json ... ``` or ``` ... ```
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```$", "", text)
    text = text.strip()
    # Extract first valid JSON object
    first = text.find("{")
    last = text.rfind("}")
    if first != -1 and last != -1:
        text = text[first : last + 1]
    return text


def _repair_json(text: str) -> str:
    """Basic heuristic repairs for slightly malformed JSON."""
    # Remove trailing commas before ] or }
    text = re.sub(r",\s*([\]}])", r"\1", text)
    return text


# ── GeminiService ─────────────────────────────────────────────────────────────

class GeminiService:
    """
    Singleton async Gemini 2.5 Flash client.

    Responsibilities:
    - Load GEMINI_API_KEY from environment variable
    - Build Gemini API requests from cached prompt templates
    - Handle retries, timeouts, markdown stripping, and JSON validation
    - Never reload prompt files after startup
    """

    _instance: Optional["GeminiService"] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def initialize(self):
        """Called once at application startup."""
        if self._initialized:
            return
        self.api_key = os.environ.get("GEMINI_API_KEY", "")
        if not self.api_key:
            logger.warning(
                "GEMINI_API_KEY is not set. Gemini requests will fail."
            )
        # Pre-load prompts into cache
        _load_prompt("medical-extraction.prompt")
        _load_prompt("summary-generation.prompt")
        self._initialized = True
        logger.info("GeminiService initialized.")

    # ── Internal request helper ───────────────────────────────────────────────

    async def _call_gemini(self, prompt_text: str) -> str:
        """
        POST to Gemini REST API with retry logic.
        Returns the raw text of the first candidate part.
        """
        if not self.api_key:
            raise RuntimeError("GEMINI_API_KEY environment variable is not set.")

        payload = {
            "contents": [
                {
                    "parts": [{"text": prompt_text}]
                }
            ],
            "generationConfig": {
                "temperature": TEMPERATURE,
                "maxOutputTokens": 2048,
            },
        }
        url = f"{GEMINI_API_URL}?key={self.api_key}"

        last_error: Exception = RuntimeError("Unknown error")
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                logger.info(f"Gemini API call attempt {attempt}/{MAX_RETRIES}")
                async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                    response = await client.post(url, json=payload)

                if response.status_code == 429:
                    wait = 2 ** attempt
                    logger.warning(f"Rate limited. Waiting {wait}s before retry.")
                    await asyncio.sleep(wait)
                    continue

                if response.status_code != 200:
                    raise RuntimeError(
                        f"Gemini API error {response.status_code}: {response.text[:300]}"
                    )

                data = response.json()
                candidates = data.get("candidates", [])
                if not candidates:
                    raise ValueError("Gemini returned no candidates.")

                content = candidates[0].get("content", {})
                parts = content.get("parts", [])
                if not parts:
                    raise ValueError("Gemini returned empty parts.")

                text = parts[0].get("text", "")
                logger.info("Gemini API call succeeded.")
                return text

            except (httpx.ConnectError, httpx.TimeoutException) as e:
                last_error = e
                logger.warning(f"Network error on attempt {attempt}: {e}")
                if attempt < MAX_RETRIES:
                    await asyncio.sleep(2 ** attempt)

            except Exception as e:
                last_error = e
                logger.error(f"Gemini call failed on attempt {attempt}: {e}")
                if attempt < MAX_RETRIES:
                    await asyncio.sleep(1)

        raise RuntimeError(
            f"Gemini API failed after {MAX_RETRIES} attempts. Last error: {last_error}"
        )

    # ── Public API ────────────────────────────────────────────────────────────

    async def extract_medical_data(self, ocr_text: str) -> dict:
        """
        Send OCR text to Gemini using the medical-extraction prompt.
        Returns a validated dict conforming to the medical extraction schema.
        """
        template = _load_prompt("medical-extraction.prompt")
        prompt = template.replace("{{OCR_TEXT}}", ocr_text)

        raw_response = await self._call_gemini(prompt)
        logger.info(f"Raw Gemini extraction response (first 200 chars): {raw_response[:200]}")

        cleaned = _strip_markdown(raw_response)
        repaired = _repair_json(cleaned)

        parsed = {}
        try:
            parsed = json.loads(repaired)
        except json.JSONDecodeError:
            logger.warning("JSON parse failed; attempting single-quote fix.")
            try:
                parsed = json.loads(repaired.replace("'", '"'))
            except json.JSONDecodeError:
                logger.error("All JSON repair attempts failed. Returning empty schema.")
                parsed = {}

        # Normalize schema
        return self._normalize_extraction(parsed)

    async def generate_summary(self, medical_data: dict) -> str:
        """
        Generate a plain-text clinical summary for an ASHA worker.
        Returns a concise string (max ~150 words).
        """
        template = _load_prompt("summary-generation.prompt")
        data_str = json.dumps(medical_data, indent=2, ensure_ascii=False)
        prompt = template.replace("{{MEDICAL_DATA}}", data_str)

        raw_response = await self._call_gemini(prompt)
        # Strip any accidental markdown
        summary = raw_response.strip()
        summary = re.sub(r"^#+\s*", "", summary, flags=re.MULTILINE)
        return summary

    # ── Schema normalizer ─────────────────────────────────────────────────────

    @staticmethod
    def _normalize_extraction(parsed: dict) -> dict:
        """Ensure the extracted dict always conforms to the expected schema."""
        medicines = []
        for med in (parsed.get("medicines") or []):
            if isinstance(med, dict):
                medicines.append({
                    "name": med.get("name") or "",
                    "dosage": med.get("dosage") or "",
                    "frequency": med.get("frequency") or "",
                    "duration": med.get("duration") or "",
                })

        lab_tests = []
        for test in (parsed.get("lab_tests") or []):
            if isinstance(test, dict):
                lab_tests.append({
                    "test_name": test.get("test_name") or "",
                    "value": test.get("value") or "",
                    "unit": test.get("unit") or "",
                    "reference_range": test.get("reference_range") or "",
                })

        return {
            "diagnosis": parsed.get("diagnosis") or None,
            "follow_up_date": parsed.get("follow_up_date") or None,
            "medicines": medicines,
            "lab_tests": lab_tests,
            "notes": parsed.get("notes") or None,
        }
