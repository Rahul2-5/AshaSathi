# Heroku Deployment Guide — ASHA Sathi Backend & Medical Vision Agent

This guide outlines the production deployment procedure for the ASHA Sathi Spring Boot backend and the OCR Python microservice on Heroku.

---

## 1. Deployment Architecture

To ensure high performance, scalability, and system stability, the application is split into two deployable units:
1. **Primary Backend (Spring Boot)**: Connects to PostgreSQL, manages auth, patient records, sync, and coordinates the Medical Vision async pipeline.
2. **Medical Vision OCR Service (Python FastAPI + PaddleOCR)**: A high-memory compute service that executes OCR text extraction.
   > [!IMPORTANT]
   > Due to the memory requirements of PaddleOCR and NumPy/Pandas, the OCR Python service should be deployed as a **separate Heroku App** (or on a cloud provider like Railway or Render with at least 1–2 GB RAM) rather than colocated with the Spring Boot server.

---

## 2. Heroku Configuration (Config Vars)

Configure the following environment variables (Config Vars) in your Heroku Dashboard under **Settings → Reveal Config Vars**:

### Spring Boot Backend App
| Config Var | Description | Example Value |
| :--- | :--- | :--- |
| `GEMINI_API_KEY` | Google Gemini API Key (for 2.5 Flash extraction and summary) | `AIzaSyB...` |
| `OCR_SERVICE_URL` | Base URL of the separately deployed Python OCR service | `https://ashasathi-ocr-service.herokuapp.com` |
| `JWT_SECRET` | Secret key used for signing and verifying JSON Web Tokens | `a-long-random-alphanumeric-string-for-security` |
| `JDBC_DATABASE_URL` | Automatically set by the Heroku Postgres add-on. If manually configured, the JDBC URL | `jdbc:postgresql://<host>:<port>/<db>` |
| `JDBC_DATABASE_USERNAME` | Username for PostgreSQL database | `postgres` |
| `JDBC_DATABASE_PASSWORD` | Password for PostgreSQL database | `password` |
| `UPLOAD_DIR` | Directory path where uploaded medical images are stored temporarily | `uploads` |

### Python OCR Service App
| Config Var | Description | Example Value |
| :--- | :--- | :--- |
| `GEMINI_API_KEY` | Google Gemini API Key (needed if executing LLM calls directly from OCR service) | `AIzaSyB...` |

---

## 3. Database Migration & Setup

The Medical Vision Agent relies on PostgreSQL and the `fuzzystrmatch` extension for Levenshtein-based fuzzy drug matching.

### Step 1: Provision Heroku Postgres
Attach a Postgres database to your Spring Boot app:
```bash
heroku addons:create heroku-postgresql:essential-0 --app ashasathi-backend
```

### Step 2: Enable fuzzystrmatch & Seed Data
Before starting the backend, connect to the Heroku database and run the migration script:
```bash
# Connect to Heroku Postgres CLI
heroku pg:psql --app ashasathi-backend

# In the psql prompt, run:
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
```

Then apply the `src/main/resources/db/V2__medical_vision.sql` script to set up schema tables (`medical_document`, `medicine`, `lab_result`, `ocr_line`) and seed master tables (`drug_master`, `lab_reference_ranges`):
```bash
heroku pg:psql --app ashasathi-backend < src/main/resources/db/V2__medical_vision.sql
```

---

## 4. Deploying the Spring Boot App

The project contains a root-level `Procfile` and `system.properties` pointing to Java 21.

### Step 1: Login and Set App
```bash
heroku login
heroku git:remote -a ashasathi-backend
```

### Step 2: Push to Heroku
Deploy the code to the Heroku remote:
```bash
git add .
git commit -m "Deploy Medical Vision Agent with Gemini 2.5 Flash support"
git push heroku master
```

Heroku will automatically:
1. Detect the Java application.
2. Build the JAR using `mvnw clean install` (ignoring tests by default if configured, or running them).
3. Start the application using the command defined in the `Procfile`:
   `web: java -Dserver.port=$PORT -jar target/AshaSathi-0.0.1-SNAPSHOT.jar`

---

## 5. Deploying the Python OCR Service (Optional/Separate App)

Create a separate Heroku App for the Python code under `ocr-service/`.

### Step 1: Create the OCR App
```bash
heroku create ashasathi-ocr-service --buildpack heroku/python
```

### Step 2: Set Build Directory
If deploying from a subdirectory of a monorepo, use the Heroku Multi-Procfile or Subdirectory buildpack, or initialize a separate git repository in `ocr-service/`:
```bash
cd ocr-service
git init
git add .
git commit -m "Initial OCR service deployment"
heroku git:remote -a ashasathi-ocr-service
git push heroku master
```

Uvicorn will automatically run on the `$PORT` provided by Heroku, launching `main:app`.
