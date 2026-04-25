@echo off
setlocal EnableExtensions EnableDelayedExpansion
title PDF Signature Stamper - Tender Documents

echo ============================================
echo  PDF Signature Stamper - Tender Documents
echo ============================================
echo.

REM ---- Locate files beside this bat ----------------------------------------
set "BAT_DIR=%~dp0"
set "EXE_PATH=%BAT_DIR%dist\stamp_signature.exe"
set "PY_SCRIPT=%BAT_DIR%stamp_signature.py"

REM ---- Prefer the standalone .exe; fall back to Python ---------------------
set "USE_EXE=0"
if exist "%EXE_PATH%" set "USE_EXE=1"

if "%USE_EXE%"=="1" (
    echo [INFO] Using standalone executable.
    echo        %EXE_PATH%
) else (
    echo [INFO] Standalone exe not found. Falling back to Python.
    echo        Run build_standalone.bat to create the .exe bundle.
    echo.

    REM ---- Set Python path ----
    set "PYTHON_EXE=C:\Users\plyid\miniforge3\python.exe"
    set "VENV_DIR=%BAT_DIR%.venv"
    set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"

    if not exist "%PYTHON_EXE%" (
        echo [ERROR] Python was not found at:
        echo         !PYTHON_EXE!
        echo         Update PYTHON_EXE in this bat file to your actual python.exe path.
        pause
        exit /b 1
    )

    if not exist "%PY_SCRIPT%" (
        echo [ERROR] stamp_signature.py not found in: %BAT_DIR%
        pause
        exit /b 1
    )

    REM ---- Create .venv if it does not exist --------------------------------
    if not exist "!VENV_PYTHON!" (
        echo [INFO] Creating virtual environment in .venv ...
        "!PYTHON_EXE!" -m venv "!VENV_DIR!"
        if errorlevel 1 (
            echo [ERROR] Failed to create virtual environment.
            pause
            exit /b 1
        )
    )
)

echo.

REM -- Auto-detect PDF --------------------------------------------------------
set PDF_COUNT=0
set PDF_FILE=

for %%F in ("%CD%\*.pdf") do (
    set /a PDF_COUNT+=1
    set "PDF_FILE=%%~fF"
)

if %PDF_COUNT% equ 1 (
    echo [AUTO] PDF  : !PDF_FILE!
) else (
    if %PDF_COUNT% equ 0 (
        echo [INFO] No PDF file found in current folder.
    ) else (
        echo [INFO] Multiple PDF files found in current folder.
    )
    set /p PDF_FILE="Enter full path to PDF file: "
    set "PDF_FILE=!PDF_FILE:"=!"
)

REM -- Auto-detect PNG --------------------------------------------------------
set PNG_COUNT=0
set PNG_FILE=

for %%F in ("%CD%\*.png") do (
    set /a PNG_COUNT+=1
    set "PNG_FILE=%%~fF"
)

if %PNG_COUNT% equ 1 (
    echo [AUTO] Sign : !PNG_FILE!
) else (
    if %PNG_COUNT% equ 0 (
        echo [INFO] No PNG file found in current folder.
    ) else (
        echo [INFO] Multiple PNG files found in current folder.
    )
    set /p PNG_FILE="Enter full path to signature PNG file: "
    set "PNG_FILE=!PNG_FILE:"=!"
)

echo.

REM -- Validate inputs --------------------------------------------------------
if not exist "!PDF_FILE!" (
    echo [ERROR] PDF file not found: !PDF_FILE!
    pause
    exit /b 1
)
if not exist "!PNG_FILE!" (
    echo [ERROR] PNG file not found: !PNG_FILE!
    pause
    exit /b 1
)

REM -- Build output path ------------------------------------------------------
for %%F in ("!PDF_FILE!") do set "OUTPUT_PDF=%%~dpnF_SIGNED%%~xF"

REM -- Install packages into .venv if using Python (not needed for .exe) -----
if "%USE_EXE%"=="0" (
    echo [STEP 1/3] Installing required Python packages into .venv ...
    "!VENV_PYTHON!" -m pip install pymupdf pypdf reportlab Pillow --quiet --disable-pip-version-check
    if errorlevel 1 (
        echo [ERROR] Failed to install packages. Check your internet connection.
        pause
        exit /b 1
    )
    echo         Done.
    echo.
)

REM -- Run stamper ------------------------------------------------------------
if "%USE_EXE%"=="1" (
    "%EXE_PATH%" "!PDF_FILE!" "!PNG_FILE!" "!OUTPUT_PDF!"
) else (
    "!VENV_PYTHON!" "%PY_SCRIPT%" "!PDF_FILE!" "!PNG_FILE!" "!OUTPUT_PDF!"
)
set EXIT_CODE=%errorlevel%

if %EXIT_CODE% neq 0 (
    echo.
    echo [ERROR] Processing failed ^(exit code %EXIT_CODE%^)
    echo         Check that the PDF is not password-protected and the PNG is valid.
    pause
    exit /b %EXIT_CODE%
)

echo.
echo Output file: !OUTPUT_PDF!
echo.

set /p OPEN_IT="Open the signed PDF now? (Y/N): "
if /i "!OPEN_IT!"=="Y" (
    start "" "!OUTPUT_PDF!"
)

pause
endlocal

