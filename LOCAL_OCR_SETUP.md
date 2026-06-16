# Local OCR Setup — Making "Analyze with AI" Work

The AI Medical Vision feature (OCR + Gemini summary) runs on **your local PC**, not on
Heroku. PaddleOCR is too heavy/expensive to host for free, so we keep it local and
expose it to the Heroku backend through a **permanent ngrok tunnel**.

## Architecture

```
Flutter app  ->  Heroku backend  ->  ngrok static domain  ->  your PC (PaddleOCR :8001)  ->  Gemini  ->  summary
```

- **Heroku backend**: `https://ashasathi-backend-44448212683b.herokuapp.com` (always on)
- **ngrok static domain**: `https://natosha-owllike-cursorily.ngrok-free.dev` (permanent)
- This domain is already saved on Heroku as the `OCR_SERVICE_URL` config var.
  **You never need to change Heroku again.**

## To enable AI analysis (do this whenever your PC was off/restarted)

Run these two, in order, and leave **both** windows open:

1. **`ocr-service/start-ocr.bat`** — starts PaddleOCR on port 8001
   (wait ~10-15s for "Application startup complete").
2. **`ocr-service/start-tunnel.bat`** — connects the permanent ngrok domain to it.

Then "Analyze with AI" in the app will generate summaries.

## To check it's working

Open in a browser (or curl):
`https://natosha-owllike-cursorily.ngrok-free.dev/health`
You should see: `{"status":"healthy","ocr_model_loaded":true,"gemini_ready":true,...}`

## Important limitations (free local setup)

- **Your PC must be ON** with both windows running for AI analysis to work.
  If the PC sleeps, shuts down, or loses internet, summaries fail until you restart
  the two scripts. (Everything else in the app — login, patients, sync — keeps
  working via Heroku regardless.)
- Prevent sleep during demos: Windows Settings -> System -> Power -> Screen and sleep
  -> set "When plugged in, put my device to sleep after" to **Never**.

## If summaries stop working — checklist

1. Are BOTH windows (OCR + ngrok) still open and running? Re-run the two `.bat` files.
2. Is the health URL above returning `healthy`?
3. Did the ngrok domain change? It shouldn't (it's your reserved static domain). If it
   ever does, update Heroku once:
   ```bash
   heroku config:set OCR_SERVICE_URL=https://<new-domain> --app ashasathi-backend
   ```
4. Gemini key: stored in `src/main/resources/application-secrets.properties` and on
   Heroku as `GEMINI_API_KEY`. Both services auto-ignore the old expired key.

## Notes

- The OCR server port is pinned to **8001** in `ocr-service/main.py` (the port the
  Heroku backend expects). Do not change it without also updating `OCR_SERVICE_URL`.
- ngrok is already authenticated on this PC (`%LOCALAPPDATA%\ngrok\ngrok.yml`).
