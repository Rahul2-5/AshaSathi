@echo off
REM ============================================================================
REM  Start the local PaddleOCR + Gemini service on port 8001.
REM  The Heroku backend reaches this via the ngrok static domain (see
REM  start-tunnel.bat). Keep this window OPEN while you use "Analyze with AI".
REM ============================================================================

cd /d "%~dp0"

echo Starting AshaSathi OCR service on http://localhost:8001 ...
echo (First start loads PaddleOCR models - give it ~10-15 seconds.)
echo Keep this window open. Press Ctrl+C to stop.
echo.

".venv\Scripts\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8001

pause
