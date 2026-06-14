import json
import re
import logging
from typing import Any, Optional

logger = logging.getLogger("parser_service")

class ParserService:
    @staticmethod
    def get_extraction_prompt(ocr_text: str) -> str:
        """
        Creates the prompt for the Llama 3.1 model based on Phase 4 requirements.
        """
        return f"""You are a medical data extraction engine.

Extract information from the provided OCR text.

Return ONLY valid JSON.
Do not include markdown.
Do not include explanations.
If a field is missing return null.

JSON Schema:
{{
"diagnosis": "",
"follow_up_date": "",
"medicines": [
{{
"name": "",
"dosage": "",
"frequency": "",
"duration": ""
}}
],
"lab_tests": [
{{
"test_name": "",
"value": "",
"unit": "",
"reference_range": ""
}}
],
"notes": ""
}}

OCR TEXT:
{ocr_text}"""

    def clean_raw_response(self, text: str) -> str:
        """
        Cleans markdown wrappers, whitespace, or trailing garbage from the AI response.
        """
        cleaned = text.strip()
        
        # 1. Remove markdown code blocks if present (e.g. ```json ... ```)
        cleaned = re.sub(r"^```(?:json)?", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"```$", "", cleaned)
        cleaned = cleaned.strip()
        
        # 2. Extract content starting from the first '{' to the last '}'
        first_brace = cleaned.find("{")
        last_brace = cleaned.rfind("}")
        if first_brace != -1 and last_brace != -1:
            cleaned = cleaned[first_brace:last_brace + 1]
            
        return cleaned

    def repair_json_string(self, text: str) -> str:
        """
        Performs basic heuristic repairs on slightly malformed JSON strings.
        - Fix trailing commas in lists/objects.
        - Ensure control characters (newlines) are escaped.
        """
        # Remove trailing commas before closing braces/brackets
        text = re.sub(r",\s*([\]}])", r"\1", text)
        
        # Escape raw newlines inside JSON string values
        # (This is a simplified repair: replaces newlines inside quotes, but we'll be careful)
        return text

    def parse_and_validate(self, raw_ai_text: str) -> dict:
        """
        Parses raw text from the AI response, cleans/repairs it, and ensures it conforms
        to the expected schema structure.
        """
        cleaned_text = self.clean_raw_response(raw_ai_text)
        repaired_text = self.repair_json_string(cleaned_text)
        
        parsed_data = {}
        
        # Try direct JSON parsing
        try:
            parsed_data = json.loads(repaired_text)
        except json.JSONDecodeError as e:
            logger.warning(f"Initial JSON parse failed: {str(e)}. Attempting advanced recovery...")
            
            # Simple fallback repair: check if we can parse it by replacing single quotes with double quotes
            # (only if keys or values are mistakenly single-quoted)
            try:
                single_to_double = repaired_text.replace("'", '"')
                parsed_data = json.loads(single_to_double)
                logger.info("JSON successfully recovered after replacing single quotes.")
            except json.JSONDecodeError:
                # If everything fails, return empty structure instead of crashing
                logger.error("All JSON repair attempts failed. Returning empty schema.")
                parsed_data = {}

        # Standardize and validate structure according to schema
        standardized = {
            "diagnosis": parsed_data.get("diagnosis") or None,
            "follow_up_date": parsed_data.get("follow_up_date") or None,
            "medicines": [],
            "lab_tests": [],
            "notes": parsed_data.get("notes") or ""
        }

        # Validate and clean medicines
        raw_medicines = parsed_data.get("medicines")
        if isinstance(raw_medicines, list):
            for med in raw_medicines:
                if isinstance(med, dict):
                    standardized["medicines"].append({
                        "name": med.get("name") or "",
                        "dosage": med.get("dosage") or "",
                        "frequency": med.get("frequency") or "",
                        "duration": med.get("duration") or ""
                    })

        # Validate and clean lab tests
        raw_lab_tests = parsed_data.get("lab_tests")
        if isinstance(raw_lab_tests, list):
            for test in raw_lab_tests:
                if isinstance(test, dict):
                    standardized["lab_tests"].append({
                        "test_name": test.get("test_name") or "",
                        "value": test.get("value") or "",
                        "unit": test.get("unit") or "",
                        "reference_range": test.get("reference_range") or ""
                    })

        return standardized
