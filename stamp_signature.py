"""
PDF Signature Stamper
- Detects scanned vs normal PDF automatically
- Normal PDF  → text-based blank detection
- Scanned PDF → image-based blank detection (pixel std-dev)
- Stamps signature PNG at bottom-left corner on every non-blank page
"""

import sys
import io
import os

import fitz  # PyMuPDF
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from PIL import Image, ImageStat


# ---------------------------------------------------------------------------
# Tunable settings
# ---------------------------------------------------------------------------
SIGN_WIDTH_MM  = 40    # Stamp width  (mm)
SIGN_HEIGHT_MM = 20    # Stamp height (mm)
MARGIN_X_MM    = 10    # Distance from left edge   (mm)
MARGIN_Y_MM    = 10    # Distance from bottom edge (mm)

# Normal-PDF blank detection
MIN_BLANK_CHARS = 50   # Pages with fewer chars than this are skipped

# Scanned-PDF type detection
SCANNED_DETECT_PAGES   = 5    # How many pages to sample
SCANNED_CHAR_THRESHOLD = 20   # Avg chars/page below this → classified as scanned

# Scanned-PDF blank-page detection
BLANK_IMG_STD_THRESHOLD = 8.0  # Grayscale pixel std-dev below this → blank
RENDER_DPI              = 72   # Low DPI keeps blank-detection fast
# ---------------------------------------------------------------------------


def detect_pdf_type(doc: fitz.Document) -> str:
    """
    Return 'scanned' or 'normal'.

    Samples up to SCANNED_DETECT_PAGES pages and measures average text length.
    A PDF whose pages are pure raster images will yield near-zero text even
    though the physical content is not blank, so image-based blank detection
    must be used instead.
    """
    n = min(SCANNED_DETECT_PAGES, len(doc))
    total_chars = sum(len(doc[i].get_text("text").strip()) for i in range(n))
    avg_chars = total_chars / n if n else 0
    return "scanned" if avg_chars < SCANNED_CHAR_THRESHOLD else "normal"


def is_blank_text(fitz_page: fitz.Page) -> bool:
    """Text-based blank detection — used for normal (non-scanned) PDFs."""
    return len(fitz_page.get_text("text").strip()) < MIN_BLANK_CHARS


def is_blank_image(fitz_page: fitz.Page) -> bool:
    """
    Image-based blank detection — used for scanned PDFs.

    Renders the page at low resolution, converts to grayscale, and checks
    the pixel standard deviation.  A mostly-white sheet has very low std-dev;
    a page with printed content has higher variance.
    """
    mat = fitz.Matrix(RENDER_DPI / 72, RENDER_DPI / 72)
    pix = fitz_page.get_pixmap(matrix=mat, colorspace=fitz.csGRAY)
    img = Image.frombytes("L", [pix.width, pix.height], pix.samples)
    std = ImageStat.Stat(img).stddev[0]
    return std < BLANK_IMG_STD_THRESHOLD


def make_stamp_overlay(page_width_pt: float, page_height_pt: float,
                       png_path: str) -> io.BytesIO:
    """Return a BytesIO PDF with the signature PNG placed at bottom-left."""
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(page_width_pt, page_height_pt))
    c.drawImage(
        png_path,
        MARGIN_X_MM  * mm,
        MARGIN_Y_MM  * mm,
        width  = SIGN_WIDTH_MM  * mm,
        height = SIGN_HEIGHT_MM * mm,
        mask   = "auto",
    )
    c.save()
    buf.seek(0)
    return buf


def main() -> None:
    if len(sys.argv) != 4:
        print("Usage: stamp_signature <pdf_path> <png_path> <out_path>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    png_path = sys.argv[2]
    out_path = sys.argv[3]

    # ---- Step 1: detect PDF type ------------------------------------------
    print("[STEP 1/3] Detecting PDF type ...")
    fitz_doc = fitz.open(pdf_path)
    pdf_type = detect_pdf_type(fitz_doc)
    blank_check = is_blank_image if pdf_type == "scanned" else is_blank_text
    type_label  = "SCANNED (image-based pages)" if pdf_type == "scanned" \
                  else "NORMAL  (text-based pages)"
    print(f"          -> {type_label}")
    print()

    # ---- Step 2: stamp pages ----------------------------------------------
    print("[STEP 2/3] Analysing PDF pages ...")
    reader  = PdfReader(pdf_path)
    writer  = PdfWriter()
    total   = len(reader.pages)
    stamped = 0

    for i, page in enumerate(reader.pages):
        blank = blank_check(fitz_doc[i])

        if blank:
            print(f"  Page {i+1:>3} / {total}  [skipped]   (blank)")
        else:
            box    = page.mediabox
            overlay = make_stamp_overlay(float(box.width), float(box.height),
                                         png_path)
            stamp  = PdfReader(overlay).pages[0]
            page.merge_page(stamp)
            stamped += 1
            print(f"  Page {i+1:>3} / {total}  [STAMPED]")

        writer.add_page(page)

    fitz_doc.close()

    # ---- Step 3: write output ---------------------------------------------
    print()
    print("[STEP 3/3] Writing output file ...")
    with open(out_path, "wb") as fh:
        writer.write(fh)

    print()
    print("=" * 55)
    print(f"  PDF type : {type_label}")
    print(f"  Done!    {stamped} of {total} pages stamped.")
    print(f"  Output   : {out_path}")
    print("=" * 55)


if __name__ == "__main__":
    main()
