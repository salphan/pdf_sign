@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Build Standalone Bundle - PDF Signature Stamper

echo ============================================
echo  Build Standalone PDF Signature Stamper
echo ============================================
echo.

REM ---- Locate Python -------------------------------------------------------
set "PYTHON_EXE=C:\Users\plyid\miniforge3\python.exe"
set "PYTHON_ROOT=C:\Users\plyid\miniforge3"
set "PYEXPAT_PYD=%PYTHON_ROOT%\DLLs\pyexpat.pyd"
set "LIBEXPAT_DLL=%PYTHON_ROOT%\Library\bin\libexpat.dll"

if not exist "%PYTHON_EXE%" (
    echo [ERROR] Python not found at: %PYTHON_EXE%
    echo         Update PYTHON_EXE in this file to your actual python.exe path.
    pause
    exit /b 1
)

if not exist "%PYEXPAT_PYD%" (
    echo [ERROR] pyexpat.pyd not found at: %PYEXPAT_PYD%
    pause
    exit /b 1
)

if not exist "%LIBEXPAT_DLL%" (
    echo [ERROR] libexpat.dll not found at: %LIBEXPAT_DLL%
    pause
    exit /b 1
)

"%PYTHON_EXE%" --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python exists but cannot be executed: %PYTHON_EXE%
    pause
    exit /b 1
)

echo [INFO] Using Python: %PYTHON_EXE%
echo.

REM ---- Locate the script ---------------------------------------------------
set "BAT_DIR=%~dp0"
set "PY_SCRIPT=%BAT_DIR%stamp_signature.py"
set "VENV_DIR=%BAT_DIR%.venv"
set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"
set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"
for %%F in ("%PY_SCRIPT%") do set "PY_SCRIPT_ABS=%%~fF"

if not exist "%PY_SCRIPT%" (
    echo [ERROR] stamp_signature.py not found in: %BAT_DIR%
    pause
    exit /b 1
)

REM ---- Step 1: Create .venv if missing ------------------------------------
if not exist "%VENV_PYTHON%" (
    echo [1/4] Creating virtual environment in .venv ...
    "%PYTHON_EXE%" -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo       Done.
) else (
    echo [1/4] Virtual environment already exists, skipping creation.
)
echo.

REM ---- Step 2: Install dependencies into .venv ----------------------------
echo [2/4] Installing required packages into .venv ...
"%VENV_PYTHON%" -m pip install pymupdf pypdf reportlab Pillow pyinstaller --quiet --disable-pip-version-check
if errorlevel 1 (
    echo [ERROR] Package installation failed. Check your internet connection.
    pause
    exit /b 1
)
echo       Done.
echo.

REM ---- Step 3: Clean previous build ----------------------------------------
if exist "%BAT_DIR%build"  rmdir /s /q "%BAT_DIR%build"
if exist "%BAT_DIR%dist\stamp_signature.exe" del /q "%BAT_DIR%dist\stamp_signature.exe"

REM ---- Step 4: Run PyInstaller from .venv ---------------------------------
echo [3/4] Running PyInstaller (this may take a minute) ...
echo       Script: %PY_SCRIPT_ABS%
set "PYINSTALLER_ARGS=--onefile --name stamp_signature --distpath %BAT_DIR%dist --workpath %BAT_DIR%build --specpath %BAT_DIR% --collect-all fitz --collect-all pymupdf --hidden-import fitz --hidden-import pypdf --hidden-import reportlab --hidden-import PIL --add-binary %PYEXPAT_PYD%;. --add-binary %LIBEXPAT_DLL%;. --noconfirm"
"%VENV_PYTHON%" -m PyInstaller %PYINSTALLER_ARGS% "%PY_SCRIPT_ABS%"

if errorlevel 1 (
    echo.
    echo [ERROR] PyInstaller failed.  See output above for details.
    pause
    exit /b 1
)

REM ---- Done ----------------------------------------------------------------
echo.
echo [4/4] Build complete!
echo.
echo   Standalone executable: %BAT_DIR%dist\stamp_signature.exe
echo.
echo   Run launcher.bat (or double-click it) to use the stamper.
echo   The launcher will automatically use the .exe instead of Python.
echo.
pause
endlocal
