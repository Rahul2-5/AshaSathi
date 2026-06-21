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
    5. PIL → OpenCV (BGR)
    6. Grayscale conversion
    7. Shadow removal (background subtraction)
    8. CLAHE contrast enhancement
    9. Deskew (Hough-line tilt correction)
    10. Bilateral denoising (preserves text edges)
    11. Adaptive binarization for high-contrast scanned documents
    12. Save as temporary PNG
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

        # ── 6. Grayscale ─────────────────────────────────────────────────────
        gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)

        # ── 7. Shadow removal ─────────────────────────────────────────────────
        # Estimate the background illumination with a large Gaussian blur
        # and divide the image by it — removes uneven lighting from phone photos.
        bg = cv2.GaussianBlur(gray, (51, 51), 0)
        shadow_removed = cv2.divide(gray, bg, scale=255)

        # ── 8. CLAHE contrast enhancement ────────────────────────────────────
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(shadow_removed)

        # ── 9. Deskew ─────────────────────────────────────────────────────────
        deskewed = _deskew(enhanced)

        # ── 10. Bilateral denoising (preserves text edges) ───────────────────
        denoised = cv2.bilateralFilter(deskewed, 9, 75, 75)

        # ── 11. Conditional Otsu binarization ────────────────────────────────
        # High std dev → photo with complex tones → skip binarization.
        # Low std dev after CLAHE → likely a high-contrast scanned document
        # where Otsu sharpens text cleanly.
        std_dev = float(np.std(denoised))
        if std_dev < 60:
            logger.info(f"Std dev {std_dev:.1f} < 60 → applying Otsu binarization")
            _, result = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        else:
            logger.info(f"Std dev {std_dev:.1f} >= 60 → skipping binarization (photo mode)")
            result = denoised

        # ── 12. Save preprocessed result ─────────────────────────────────────
        out_path = file_path + "_preprocessed.png"
        cv2.imwrite(out_path, result)
        logger.info(f"Preprocessing complete → {out_path}")
        return out_path


def _deskew(image: np.ndarray) -> np.ndarray:
    """
    Detect and correct document skew using Hough line detection.
    Only corrects if the detected angle is between 0.5° and 15° to avoid
    rotating diagrams or naturally tilted content.
    """
    try:
        edges = cv2.Canny(image, 50, 150, apertureSize=3)
        lines = cv2.HoughLinesP(
            edges,
            rho=1,
            theta=np.pi / 180,
            threshold=100,
            minLineLength=max(image.shape[1] // 8, 50),
            maxLineGap=10,
        )
        if lines is None:
            return image

        angles = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            if x2 != x1:
                angle = np.degrees(np.arctan2(y2 - y1, x2 - x1))
                if -45 < angle < 45:
                    angles.append(angle)

        if not angles:
            return image

        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.5 or abs(median_angle) > 15:
            return image

        logger.info(f"Deskewing by {median_angle:.2f}°")
        h, w = image.shape[:2]
        M = cv2.getRotationMatrix2D((w / 2, h / 2), median_angle, 1.0)
        return cv2.warpAffine(
            image, M, (w, h),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_REPLICATE,
        )
    except Exception as e:
        logger.warning(f"Deskew failed, returning original: {e}")
        return image
