@echo off
REM ============================================================================
REM  Expose the local OCR service (port 8001) to the internet on a PERMANENT
REM  ngrok domain, so the Heroku backend can reach it.
REM
REM  This domain is already set on Heroku as OCR_SERVICE_URL, so you NEVER need
REM  to change Heroku again - just run this whenever your PC restarts.
REM
REM  Start start-ocr.bat FIRST, then this. Keep both windows open.
REM ============================================================================

echo Starting ngrok tunnel -> https://natosha-owllike-cursorily.ngrok-free.dev
echo Keep this window open. Press Ctrl+C to stop.
echo.

ngrok http 8001 --url=https://natosha-owllike-cursorily.ngrok-free.dev

pause
