@echo off
title Nova Launcher
echo NOVA - Windows Start Script
echo ==========================================================
echo.

:: Ensure we are in the project root directory
cd /d "%~dp0"

:: ---------------------------------------------------------------
:: [0/3] Make sure Node dependencies are installed. If node_modules
:: is missing (fresh clone / first run), "npm run dev" would just
:: fail with "'tsx' is not recognized" because tsx only exists
:: inside node_modules\.bin after an install.
:: ---------------------------------------------------------------
if not exist "node_modules\" (
    echo [0/3] node_modules not found - running "npm install" first...
    echo       ^(this only needs to happen once and can take a minute^)
    call npm install
    if errorlevel 1 (
        echo.
        echo ERROR: npm install failed. Fix the error above and re-run this script.
        pause
        exit /b 1
    )
) else if not exist "node_modules\.bin\tsx.cmd" (
    echo [0/3] node_modules looks incomplete - re-running "npm install"...
    call npm install
    if errorlevel 1 (
        echo.
        echo ERROR: npm install failed. Fix the error above and re-run this script.
        pause
        exit /b 1
    )
)

:: ---------------------------------------------------------------
:: [1/3] Launch the Python desktop agent.
:: Prefer a local venv if one exists; otherwise fall back to the
:: "python" on PATH. Either way, quickly sanity-check that the
:: required packages (fastapi, uvicorn, pydantic) are importable so
:: we don't open a window that just silently crashes.
:: ---------------------------------------------------------------
set "PYEXE=python"
if exist "venv\Scripts\python.exe" set "PYEXE=venv\Scripts\python.exe"

echo [1/3] Checking Python agent dependencies (%PYEXE%)...
"%PYEXE%" -c "import fastapi, uvicorn, pydantic" 2>nul
if errorlevel 1 (
    echo       Required Python packages missing - installing from agent\requirements.txt...
    "%PYEXE%" -m pip install -r agent\requirements.txt
    if errorlevel 1 (
        echo.
        echo ERROR: pip install failed. Fix the error above and re-run this script.
        pause
        exit /b 1
    )
)

echo [2/3] Launching Python Desktop Agent...
start "Nova Desktop Agent (Python)" cmd /k ""%PYEXE%" run_agent.py"

:: Wait for the agent to initialize
timeout /t 2 /nobreak >nul

echo [3/3] Launching Node.js Server ^& Vite Frontend...
start "Nova Web Server (Node)" cmd /k "npm run dev"

echo.
echo ==========================================================
echo NOVA IS RUNNING!
echo.
echo Open your browser to: http://localhost:3000
echo Automatically launching Microsoft Edge...
timeout /t 3 /nobreak >nul
start msedge http://localhost:3000
echo.
echo Note: The Python agent and Node server are running in the
echo two newly opened command prompt windows. If either window
echo shows an error and closes, re-read the message in it - that
echo is the real cause, not the browser "connection refused" page.
echo To STOP Nova, simply close those two windows.
echo ==========================================================
echo.
pause
