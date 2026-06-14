import cv2
import numpy as np
import logging
from PIL import Image, ImageOps

logger = logging.getLogger("image_preprocessor")

MAX_DIMENSION = 1600


class ImagePreprocessor:
    """
    Standalone image preprocessing pipeline optimised for medical document OCR.

    Steps:
    1. Validate image (PIL verify)
    2. EXIF auto-rotate
    3. Resize oversized images (max 1600px on longest side)
    4. Convert to RGB
    5. CLAHE contrast enhancement on grayscale
    6. Bilateral denoising (preserves text edges)
    7. Save as temporary PNG
    """

    @staticmethod
    def preprocess(file_path: str) -> str:
        """
        Apply the full preprocessing pipeline to the image at file_path.
        Returns the path to the preprocessed image (caller must delete it).
        Raises ValueError on invalid / corrupt image.
        """
        logger.info(f"Preprocessing image: {file_path}")

        # ── 1. Validate ──────────────────────────────────────────────────────
        try:
            with Image.open(file_path) as img:
                img.verify()
        except Exception as e:
            raise ValueError(f"Invalid or corrupted image: {e}")

        # ── 2. Re-open + EXIF rotate ─────────────────────────────────────────
        img = Image.open(file_path)
        img = ImageOps.exif_transpose(img)

        # ── 3. Resize ────────────────────────────────────────────────────────
        if img.width > MAX_DIMENSION or img.height > MAX_DIMENSION:
            logger.info(
                f"Resizing from {img.width}x{img.height} → max {MAX_DIMENSION}px"
            )
            img.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.Resampling.LANCZOS)

        # ── 4. Convert to RGB ────────────────────────────────────────────────
        if img.mode != "RGB":
            img = img.convert("RGB")

        # ── 5. PIL → OpenCV (BGR) ────────────────────────────────────────────
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)

        # ── 6. Grayscale + CLAHE contrast enhancement ────────────────────────
        gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # ── 7. Bilateral denoising (preserves text edges) ───────────────────
        denoised = cv2.bilateralFilter(enhanced, 9, 75, 75)

        # ── 8. Save preprocessed result ──────────────────────────────────────
        out_path = file_path + "_preprocessed.png"
        cv2.imwrite(out_path, denoised)
        logger.info(f"Preprocessing complete → {out_path}")
        return out_path
