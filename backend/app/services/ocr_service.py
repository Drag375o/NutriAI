"""Reads text from an uploaded image, locally.

Tesseract runs on this machine, so a prescription photograph never leaves
it. Only the text the user reviews and confirms is ever sent anywhere.

The image is held in memory and never written to disk.
"""

import io
import re

from PIL import Image, ImageEnhance, ImageOps

import pytesseract

from app.core.config import settings

if settings.TESSERACT_PATH:
    pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_PATH

# Anything larger is a phone photograph at full resolution, which is slower
# to process without being more accurate.
MAX_DIMENSION = 2000

# Below this, upscaling helps: Tesseract struggles with small type.
MIN_DIMENSION = 1000

MAX_BYTES = 8 * 1024 * 1024


class OcrError(Exception):
    """Extraction failed in a way worth showing the user."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


def is_available() -> bool:
    """Whether Tesseract can actually be run.

    Checked before offering the feature, so a missing install produces an
    explanation rather than a failed upload.
    """
    try:
        pytesseract.get_tesseract_version()
        return True
    except Exception:
        return False


def _prepare(image: Image.Image) -> Image.Image:
    """Greyscale, straighten contrast, and size for legibility.

    Phone photographs of printed text are usually low contrast and either
    too large or too small. Four lines here lift accuracy noticeably.
    """
    # EXIF rotation, or a photograph taken sideways reads as gibberish.
    image = ImageOps.exif_transpose(image)
    image = image.convert("L")

    # Stretches the histogram, which separates ink from paper.
    image = ImageOps.autocontrast(image)
    image = ImageEnhance.Sharpness(image).enhance(1.4)

    longest = max(image.size)

    if longest > MAX_DIMENSION:
        scale = MAX_DIMENSION / longest
    elif longest < MIN_DIMENSION:
        scale = MIN_DIMENSION / longest
    else:
        scale = 1

    if scale != 1:
        image = image.resize(
            (int(image.width * scale), int(image.height * scale)),
            Image.LANCZOS,
        )

    return image


def _tidy(text: str) -> str:
    """Clean up the raw output without changing what it says.

    Tesseract produces stray whitespace and empty lines around anything it
    is unsure of. Removing those makes the review screen readable; nothing
    here alters a word.
    """
    lines = [line.strip() for line in text.splitlines()]
    lines = [re.sub(r"\s{2,}", " ", line) for line in lines if line]
    return "\n".join(lines)


def extract(content: bytes) -> str:
    """Read the text out of an image.

    Returns whatever Tesseract produced, tidied but not interpreted. The
    caller shows it to the user for correction; nothing downstream should
    treat this as reliable.
    """
    if len(content) > MAX_BYTES:
        raise OcrError("That image is too large. Keep it under 8 MB.")

    if not is_available():
        raise OcrError(
            "Text extraction is not set up on this machine. Install "
            "Tesseract and set TESSERACT_PATH."
        )

    try:
        image = Image.open(io.BytesIO(content))
    except Exception:
        raise OcrError("That file could not be read as an image.")

    try:
        prepared = _prepare(image)
        raw = pytesseract.image_to_string(prepared)
    except Exception:
        raise OcrError("Could not read that image. Try a clearer photograph.")

    text = _tidy(raw)

    if len(text) < 10:
        raise OcrError(
            "No readable text was found. Try a clearer photograph, with the "
            "page flat and well lit."
        )

    return text