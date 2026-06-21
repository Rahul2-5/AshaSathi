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

GEMINI_API_TEMPLATE = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent"
)
GEMINI_MODELS = ["gemini-2.5-flash", "gemini-2.0-flash"]
RETRYABLE_STATUS = {429, 500, 502, 503, 504}
MAX_RETRIES = 4
TIMEOUT_SECONDS = 45.0
TEMPERATURE = 0.0


# ── Response cleaner ─────────────────────────────────────────────────────────

def _strip_markdown(text: str) -> str:
    """Remove markdown code fences and surrounding whitespace."""
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```$", "", text)
    text = text.strip()
    first = text.find("{")
    last = text.rfind("}")
    if first != -1 and last != -1:
        text = text[first : last + 1]
    return text


def _repair_json(text: str) -> str:
    """Basic heuristic repairs for slightly malformed JSON."""
    text = re.sub(r",\s*([\]}])", r"\1", text)
    return text


def _loads_lenient(text: str) -> dict:
    """
    Parse Gemini JSON defensively. strict=False tolerates literal newlines/tabs
    inside string values (common when a free-text summary is embedded in JSON).
    Falls back to a single-quote fix, then to an empty dict.
    """
    for attempt in (text, text.replace("'", '"')):
        try:
            result = json.loads(attempt, strict=False)
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            continue
    logger.error("All JSON repair attempts failed. Returning empty schema.")
    return {}


# ── GeminiService ─────────────────────────────────────────────────────────────

class GeminiService:
    """
    Singleton async Gemini 2.5 Flash client.

    Responsibilities:
    - Load GEMINI_API_KEY from environment variable
    - Build Gemini API requests using system_instruction + user content
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
        if self.api_key == "AIzaSyBbjSFuewpKa_yf8FLl-AZ75tuSHirv_CE":
            logger.warning("Expired environment API key detected. Using fallbacks.")
            self.api_key = ""

        # Fallback 1: Read from .env file
        if not self.api_key:
            for path in [Path(".env"), Path("../.env"), Path("ocr-service/.env")]:
                if path.exists():
                    try:
                        for line in path.read_text(encoding="utf-8").splitlines():
                            if line.strip().startswith("GEMINI_API_KEY="):
                                self.api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                                logger.info(f"Loaded GEMINI_API_KEY from {path}")
                                break
                    except Exception as e:
                        logger.warning(f"Error reading {path}: {e}")
                if self.api_key:
                    break

        # Fallback 2: Read from Spring Boot properties files
        if not self.api_key:
            paths_to_try = [
                Path("src/main/resources/application-secrets.properties"),
                Path("../src/main/resources/application-secrets.properties"),
                Path("Backend/src/main/resources/application-secrets.properties"),
                Path("../Backend/src/main/resources/application-secrets.properties"),
                Path("../../src/main/resources/application-secrets.properties")
            ]
            for path in paths_to_try:
                if path.exists():
                    try:
                        for line in path.read_text(encoding="utf-8").splitlines():
                            if "GEMINI_API_KEY=" in line or "gemini.api.key=" in line:
                                self.api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                                logger.info(f"Loaded GEMINI_API_KEY from Spring config {path}")
                                break
                    except Exception as e:
                        logger.warning(f"Error reading Spring config {path}: {e}")
                if self.api_key:
                    break

        if not self.api_key:
            logger.warning("GEMINI_API_KEY is not set. Gemini requests will fail.")

        # Pre-load all prompts into cache
        _load_prompt("medical-extraction.prompt")
        _load_prompt("summary-generation.prompt")
        _load_prompt("extract-and-summarize.prompt")
        _load_prompt("system-instruction.prompt")
        self._initialized = True
        logger.info("GeminiService initialized.")

    # ── Internal request helper ───────────────────────────────────────────────

    async def _call_gemini(self, system_text: str, user_text: str) -> str:
        """
        POST to Gemini REST API with system_instruction + user content.
        Retries transient failures with exponential backoff across model fallbacks.
        """
        if not self.api_key:
            raise RuntimeError("GEMINI_API_KEY environment variable is not set.")

        payload = {
            "system_instruction": {
                "parts": [{"text": system_text}]
            },
            "contents": [{"parts": [{"text": user_text}]}],
            "generationConfig": {
                "temperature": TEMPERATURE,
                "maxOutputTokens": 4096,
            },
        }

        last_error: Exception = RuntimeError("Unknown error")
        for model in GEMINI_MODELS:
            url = f"{GEMINI_API_TEMPLATE.format(model=model)}?key={self.api_key}"
            for attempt in range(1, MAX_RETRIES + 1):
                try:
                    logger.info(f"Gemini API call: model={model} attempt={attempt}/{MAX_RETRIES}")
                    async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
                        response = await client.post(url, json=payload)

                    if response.status_code in RETRYABLE_STATUS:
                        wait = 2 ** attempt
                        last_error = RuntimeError(
                            f"Gemini {model} transient {response.status_code}: {response.text[:200]}"
                        )
                        logger.warning(
                            f"{model} returned {response.status_code} (transient). "
                            f"Waiting {wait}s before retry."
                        )
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
                    logger.info(f"Gemini API call succeeded (model={model}).")
                    return text

                except (httpx.ConnectError, httpx.TimeoutException) as e:
                    last_error = e
                    logger.warning(f"Network error on {model} attempt {attempt}: {e}")
                    if attempt < MAX_RETRIES:
                        await asyncio.sleep(2 ** attempt)

                except RuntimeError as e:
                    last_error = e
                    logger.error(f"Non-retryable error on {model}: {e}")
                    break

                except Exception as e:
                    last_error = e
                    logger.error(f"Gemini call failed on {model} attempt {attempt}: {e}")
                    if attempt < MAX_RETRIES:
                        await asyncio.sleep(2 ** attempt)

            logger.warning(f"Model {model} exhausted; falling back to next model if available.")

        raise RuntimeError(
            f"Gemini API failed across models {GEMINI_MODELS}. Last error: {last_error}"
        )

    # ── Public API ────────────────────────────────────────────────────────────

    async def extract_medical_data(self, ocr_text: str) -> dict:
        """
        Send OCR text to Gemini using the medical-extraction prompt.
        Returns a validated dict conforming to the medical extraction schema.
        """
        system_text = _load_prompt("system-instruction.prompt")
        template = _load_prompt("medical-extraction.prompt")
        user_text = template.replace("{{OCR_TEXT}}", ocr_text)

        raw_response = await self._call_gemini(system_text, user_text)
        logger.info(f"Raw Gemini extraction response (first 200 chars): {raw_response[:200]}")

        cleaned = _strip_markdown(raw_response)
        repaired = _repair_json(cleaned)
        parsed = _loads_lenient(repaired)
        return self._normalize_extraction(parsed)

    async def extract_and_summarize(
        self,
        ocr_text: str,
        patient_age: Optional[int] = None,
        patient_gender: Optional[str] = None,
    ) -> tuple[dict, str, str]:
        """
        Single Gemini call that returns structured medical data, a clinical
        summary, and ASHA worker action items.

        Returns: (normalized_data_dict, summary_str, asha_actions_str)
        """
        system_text = _load_prompt("system-instruction.prompt")
        template = _load_prompt("extract-and-summarize.prompt")

        age_str = str(patient_age) if patient_age is not None else "unknown"
        gender_str = patient_gender if patient_gender else "unknown"

        user_text = (
            template
            .replace("{{OCR_TEXT}}", ocr_text)
            .replace("{{PATIENT_AGE}}", age_str)
            .replace("{{PATIENT_GENDER}}", gender_str)
        )

        raw_response = await self._call_gemini(system_text, user_text)
        logger.info(f"Raw Gemini combined response (first 200 chars): {raw_response[:200]}")

        cleaned = _strip_markdown(raw_response)
        repaired = _repair_json(cleaned)
        parsed = _loads_lenient(repaired)

        summary = re.sub(r"^#+\s*", "", (parsed.get("summary") or "").strip(), flags=re.MULTILINE)
        asha_actions = (parsed.get("asha_actions") or "").strip()

        return self._normalize_extraction(parsed), summary, asha_actions

    async def generate_summary(self, medical_data: dict) -> str:
        """
        Generate a plain-text clinical summary for an ASHA worker.
        Returns a concise string (max ~200 words).
        """
        system_text = _load_prompt("system-instruction.prompt")
        template = _load_prompt("summary-generation.prompt")
        data_str = json.dumps(medical_data, indent=2, ensure_ascii=False)
        user_text = template.replace("{{MEDICAL_DATA}}", data_str)

        raw_response = await self._call_gemini(system_text, user_text)
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
            "document_type": parsed.get("document_type") or None,
            "diagnosis": parsed.get("diagnosis") or None,
            "doctor_name": parsed.get("doctor_name") or None,
            "hospital_name": parsed.get("hospital_name") or None,
            "follow_up_date": parsed.get("follow_up_date") or None,
            "medicines": medicines,
            "lab_tests": lab_tests,
            "notes": parsed.get("notes") or None,
        }
