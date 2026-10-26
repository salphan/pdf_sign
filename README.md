# PDF Signature Stamper

Stamps a signature image onto every non-blank page of a PDF at the **bottom-left corner**.
Automatically distinguishes **scanned PDFs** (image-only pages) from **normal text PDFs** and applies the appropriate blank-page detection method for each.

---

## Files

| File | Purpose |
|---|---|
| `stamp_signature.py` | Python processing logic |
| `stamp_signature_v02.bat` | Double-click launcher — handles file detection and user input |
| `build_standalone.bat` | Run once to build a self-contained `dist\stamp_signature.exe` |
| `requirements.txt` | Python package list |

---

## Quick Start (Standalone — no Python needed after build)

1. Run `build_standalone.bat` **once**.  
   It installs packages and creates `dist\stamp_signature.exe`.
2. Place your PDF and signature PNG in the parent direcetory folder.
3. Double-click `stamp_signature_v02.bat` — it will auto-detect and use the `.exe`.

---

## Quick Start (Python fallback)

If you haven't built the `.exe`, the launcher falls back to Python automatically:

- **Python 3.8+** must be installed.
- Required packages are installed automatically on first run:  
  `pymupdf`, `pypdf`, `reportlab`, `Pillow`

---

## PDF Type Detection

| PDF Type | How blank pages are detected |
|---|---|
| **Normal** (text-based) | Pages with fewer than 50 extracted characters are skipped |
| **Scanned** (image-based) | Pages are rendered and checked for pixel variance; near-white pages (std-dev < 8) are skipped |

Detection samples up to the first 5 pages: if average text length is below 20 characters the document is classified as **scanned**.

---

## Stamp Position & Size

Adjustable at the top of `stamp_signature.py`:

| Setting | Default | Description |
|---|---|---|
| `SIGN_WIDTH_MM` | `40` | Width of the stamp (mm) |
| `SIGN_HEIGHT_MM` | `20` | Height of the stamp (mm) |
| `MARGIN_X_MM` | `10` | Distance from left edge (mm) |
| `MARGIN_Y_MM` | `10` | Distance from bottom edge (mm) |
| `MIN_BLANK_CHARS` | `50` | Normal PDF: char count below this → blank |
| `SCANNED_CHAR_THRESHOLD` | `20` | Avg chars/page below this → classified as scanned |
| `BLANK_IMG_STD_THRESHOLD` | `8.0` | Scanned PDF: pixel std-dev below this → blank |

---

## Output

```
[STEP 1/3] Detecting PDF type ...
          → SCANNED (image-based pages)

[STEP 2/3] Analysing PDF pages ...
  Page   1 /  42  [STAMPED]
  Page   2 /  42  [skipped]   (blank)
  Page   3 /  42  [STAMPED]
  ...

[STEP 3/3] Writing output file ...

=======================================================
  PDF type : SCANNED (image-based pages)
  Done!    40 of 42 pages stamped.
  Output   : C:\...\tender_SIGNED.pdf
=======================================================
```

The signed PDF is saved in the same folder as the original with `_SIGNED` appended.

---

## License

This project is licensed under the MIT License.

You are free to use, modify, and build features on top of this project, provided that the original copyright and permission notice are retained.

Attribution: WIOX | SEPL - Salphan Energy Pvt Ltd.
