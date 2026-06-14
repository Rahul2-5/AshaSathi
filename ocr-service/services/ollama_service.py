import httpx
import logging
import json
from typing import Optional

logger = logging.getLogger("ollama_service")

class OllamaService:
    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3.1:8b-instruct-q4_0"):
        self.base_url = base_url
        self.model = model
        self.generate_url = f"{self.base_url}/api/generate"

    async def generate_json(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """
        Sends a generation request to the local Ollama server, requesting raw JSON text.
        """
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.0  # Keep temperature 0 for deterministic medical data extraction
            }
        }
        if system_prompt:
            payload["system"] = system_prompt

        logger.info(f"Sending request to Ollama ({self.model}) at {self.generate_url}")
        
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(self.generate_url, json=payload)
                if response.status_code != 200:
                    logger.error(f"Ollama server returned status {response.status_code}: {response.text}")
                    raise RuntimeError(f"Ollama server error: Status {response.status_code}")
                
                response_json = response.json()
                response_text = response_json.get("response", "")
                logger.info("Successfully received response from Ollama.")
                return response_text
                
        except httpx.ConnectError:
            logger.error("Could not connect to Ollama. Make sure Ollama is running on localhost:11434.")
            raise ConnectionError("Ollama service is unreachable. Is Ollama running?")
        except Exception as e:
            logger.error(f"Error communicating with Ollama: {str(e)}")
            raise e
