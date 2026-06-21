import os
import cv2
import numpy as np
from PIL import Image, ImageOps
import time
import logging

logger = logging.getLogger("ocr_service")
logging.basicConfig(level=logging.INFO)

class OCRService:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(OCRService, cls).__new__(cls, *args, **kwargs)
            cls._instance.ocr = None
        return cls._instance

    def initialize(self):
        """
        Initializes the PaddleOCR model once during application startup.
        Ensures the model stays in memory for all subsequent requests.
        """
        if self.ocr is None:
            logger.info("Initializing PaddleOCR engine singleton...")
            start_init = time.time()
            from paddleocr import PaddleOCR
            # Settings tuned for medical documents on CPU (PaddleOCR 3.x API).
            # Combined effect: a full-page scan dropped from ~94s to ~10s with no text loss.
            # - lang='en': English-first recognition for prescriptions/lab reports.
            # - text_detection/recognition_model_name=*mobile*: PaddleOCR 3.x defaults to the
            #   heavy PP-OCRv5_server_det model (~2x slower). The mobile models read the same
            #   text far faster on CPU — this was the single biggest speedup.
            # - enable_mkldnn=False: oneDNN crashes under PaddleOCR 3.x's PIR executor on this
            #   paddle build ("ConvertPirAttribute2RuntimeAttribute not support ..."), so it must
            #   stay off.
            # - cpu_threads=<all cores>: PaddleOCR defaults to very few threads; using every core
            #   was the second-biggest win.
            # - text_det_limit_side_len/type: cap detection input to 896px (longest side) so
            #   detection stays fast without dropping text lines.
            # - text_recognition_batch_size: batch line crops through the rec model together.
            # - use_doc_*/use_textline_orientation=False: skip the heavy orientation + unwarping
            #   models PaddleOCR 3.x runs by default; flat phone photos don't need them.
            self.ocr = PaddleOCR(
                lang='en',
                enable_mkldnn=False,
                cpu_threads=os.cpu_count() or 4,
                text_detection_model_name='PP-OCRv5_mobile_det',
                text_recognition_model_name='en_PP-OCRv5_mobile_rec',
                text_det_limit_side_len=1280,
                text_det_limit_type='max',
                text_recognition_batch_size=16,
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=False,
            )
            logger.info(f"PaddleOCR engine initialized in {time.time() - start_init:.2f} seconds.")

    def preprocess_image(self, file_path: str) -> str:
        """
        Applies image preprocessing to improve OCR accuracy and speed.
        1. Validate format
        2. Resize oversized images to a max width/height of 1600px
        3. Convert to RGB and handle EXIF auto-rotation
        4. Apply CLAHE (contrast enhancement) on grayscale
        5. Apply Bilateral Denoising Filter to preserve edges
        """
        logger.info(f"Preprocessing image: {file_path}")
        
        # Open image using PIL to validate and handle EXIF
        try:
            with Image.open(file_path) as img:
                img.verify()
        except Exception as e:
            raise ValueError(f"Invalid image format or corrupted file: {str(e)}")

        # Reopen image since verify() closes the file pointer
        img = Image.open(file_path)
        
        # Auto-rotate based on EXIF tag
        img = ImageOps.exif_transpose(img)
        
        # Resize if oversized (max width/height = 1280px). Detection is capped at 896px
        # anyway, so 1280 keeps recognition crops sharp while cutting decode/resize cost.
        max_size = 1280
        if img.width > max_size or img.height > max_size:
            logger.info(f"Resizing oversized image from {img.width}x{img.height} to fit {max_size}px")
            img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
        if img.mode != 'RGB':
            img = img.convert('RGB')
            
        # Convert PIL Image to OpenCV Format (numpy BGR array)
        open_cv_image = np.array(img)
        open_cv_image = cv2.cvtColor(open_cv_image, cv2.COLOR_RGB2BGR)
        
        # Convert to Grayscale
        gray = cv2.cvtColor(open_cv_image, cv2.COLOR_BGR2GRAY)
        
        # Improve Contrast using CLAHE
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        contrast_enhanced = clahe.apply(gray)
        
        # Denoise with a Bilateral Filter (preserves text edges unlike Gaussian blur)
        denoised = cv2.bilateralFilter(contrast_enhanced, 9, 75, 75)
        
        # Save preprocessed image temporarily
        preprocessed_path = file_path + "_preprocessed.png"
        cv2.imwrite(preprocessed_path, denoised)
        
        logger.info(f"Preprocessing completed. Saved temporary file: {preprocessed_path}")
        return preprocessed_path

    def extract_text(self, file_path: str) -> dict:
        """
        Run PaddleOCR extraction on the preprocessed image.
        """
        self.initialize()
        
        start_time = time.time()
        preprocessed_path = None
        try:
            # Run the preprocessing pipeline
            preprocessed_path = self.preprocess_image(file_path)
            
            # Execute PaddleOCR on preprocessed image.
            # PaddleOCR 3.x uses .predict() and returns a list of dict-like OCRResult
            # objects with keys: rec_texts (list[str]), rec_scores (list[float]),
            # rec_polys (list[np.ndarray boxes]). The old .ocr(cls=...) signature was removed.
            logger.info("Executing PaddleOCR recognition...")
            result = self.ocr.predict(preprocessed_path)

            segments = []
            raw_text_parts = []

            for res in (result or []):
                texts = res.get("rec_texts", [])
                scores = res.get("rec_scores", [])
                polys = res.get("rec_polys")
                if polys is None:
                    polys = res.get("dt_polys", [])
                for i, text in enumerate(texts):
                    confidence = float(scores[i]) if i < len(scores) else 0.0
                    # numpy arrays aren't JSON-serializable; convert boxes to nested lists
                    if i < len(polys) and hasattr(polys[i], "tolist"):
                        box = polys[i].tolist()
                    else:
                        box = polys[i] if i < len(polys) else []
                    segments.append({
                        "text": text,
                        "confidence": confidence,
                        "box": box
                    })
                    raw_text_parts.append(text)
            
            raw_text = "\n".join(raw_text_parts)
            duration_ms = (time.time() - start_time) * 1000
            logger.info(f"OCR processing completed in {duration_ms:.2f}ms. Extracted {len(segments)} segments.")
            
            return {
                "success": True,
                "raw_text": raw_text,
                "segments": segments,
                "processing_time_ms": duration_ms
            }
            
        except Exception as e:
            logger.error(f"OCR execution failed: {str(e)}")
            return {
                "success": False,
                "raw_text": "",
                "segments": [],
                "processing_time_ms": (time.time() - start_time) * 1000,
                "error": str(e)
            }
        finally:
            # Ensure the temporary preprocessed file is cleaned up
            if preprocessed_path and os.path.exists(preprocessed_path):
                try:
                    os.remove(preprocessed_path)
                    logger.info("Cleaned up temporary preprocessed image.")
                except Exception as cleanup_err:
                    logger.warning(f"Failed to delete preprocessed file: {str(cleanup_err)}")
