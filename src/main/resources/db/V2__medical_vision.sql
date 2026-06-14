-- ============================================================
-- V2: Medical Vision Agent Database Schema
-- Run manually via psql or execute at startup via JdbcTemplate
-- ============================================================

-- Enable fuzzy string matching for Levenshtein drug validation
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- ── medical_document ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS medical_document (
    id                  BIGSERIAL PRIMARY KEY,
    patient_id          BIGINT,
    image_path          VARCHAR(512),
    raw_text            TEXT,
    diagnosis           VARCHAR(1000),
    follow_up_date      DATE,
    ai_summary          TEXT,
    processing_status   VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                            CHECK (processing_status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
    confidence_score    DOUBLE PRECISION,
    error_message       VARCHAR(500),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medical_doc_patient ON medical_document(patient_id);
CREATE INDEX IF NOT EXISTS idx_medical_doc_status  ON medical_document(processing_status);

-- ── medicine ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS medicine (
    id                  BIGSERIAL PRIMARY KEY,
    document_id         BIGINT NOT NULL REFERENCES medical_document(id) ON DELETE CASCADE,
    medicine_name       VARCHAR(300) NOT NULL,
    dosage              VARCHAR(100),
    frequency           VARCHAR(100),
    duration            VARCHAR(100),
    verified            BOOLEAN NOT NULL DEFAULT FALSE,
    matched_drug_name   VARCHAR(300),
    match_score         INT
);

CREATE INDEX IF NOT EXISTS idx_medicine_document ON medicine(document_id);

-- ── lab_result ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS lab_result (
    id                  BIGSERIAL PRIMARY KEY,
    document_id         BIGINT NOT NULL REFERENCES medical_document(id) ON DELETE CASCADE,
    test_name           VARCHAR(300) NOT NULL,
    value               VARCHAR(100),
    unit                VARCHAR(50),
    reference_range     VARCHAR(200),
    severity            VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
                            CHECK (severity IN ('NORMAL','LOW','HIGH','CRITICAL'))
);

CREATE INDEX IF NOT EXISTS idx_lab_result_document ON lab_result(document_id);

-- ── ocr_line ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ocr_line (
    id                  BIGSERIAL PRIMARY KEY,
    document_id         BIGINT NOT NULL REFERENCES medical_document(id) ON DELETE CASCADE,
    extracted_text      TEXT NOT NULL,
    confidence          DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    confidence_level    VARCHAR(20),
    line_order          INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_ocr_line_document ON ocr_line(document_id);

-- ── drug_master ───────────────────────────────────────────────────────────────
-- Seed data: common drugs used in ASHA worker context (India)

CREATE TABLE IF NOT EXISTS drug_master (
    id          BIGSERIAL PRIMARY KEY,
    drug_name   VARCHAR(300) NOT NULL UNIQUE,
    category    VARCHAR(100),
    created_at  TIMESTAMP DEFAULT NOW()
);

INSERT INTO drug_master (drug_name, category) VALUES
    ('Paracetamol',           'Analgesic/Antipyretic'),
    ('Paracetamol 500mg',     'Analgesic/Antipyretic'),
    ('Ibuprofen',             'NSAID'),
    ('Aspirin',               'Antiplatelet/Analgesic'),
    ('Amoxicillin',           'Antibiotic'),
    ('Amoxicillin 500mg',     'Antibiotic'),
    ('Azithromycin',          'Antibiotic'),
    ('Metformin',             'Antidiabetic'),
    ('Metformin 500mg',       'Antidiabetic'),
    ('Metformin 1000mg',      'Antidiabetic'),
    ('Glibenclamide',         'Antidiabetic'),
    ('Atorvastatin',          'Statin'),
    ('Atorvastatin 10mg',     'Statin'),
    ('Atorvastatin 20mg',     'Statin'),
    ('Amlodipine',            'Antihypertensive'),
    ('Amlodipine 5mg',        'Antihypertensive'),
    ('Enalapril',             'Antihypertensive/ACE Inhibitor'),
    ('Losartan',              'Antihypertensive/ARB'),
    ('Omeprazole',            'Proton Pump Inhibitor'),
    ('Omeprazole 20mg',       'Proton Pump Inhibitor'),
    ('Pantoprazole',          'Proton Pump Inhibitor'),
    ('Ranitidine',            'H2 Blocker'),
    ('Iron Tablet',           'Haematinic'),
    ('Ferrous Sulphate',      'Haematinic'),
    ('Folic Acid',            'Vitamin'),
    ('Folic Acid 5mg',        'Vitamin'),
    ('Vitamin D3',            'Vitamin'),
    ('Calcium',               'Mineral Supplement'),
    ('Calcium Carbonate',     'Mineral Supplement'),
    ('ORS',                   'Rehydration'),
    ('Oral Rehydration Salts','Rehydration'),
    ('Zinc',                  'Micronutrient'),
    ('Zinc 20mg',             'Micronutrient'),
    ('Albendazole',           'Antiparasitic'),
    ('Ivermectin',            'Antiparasitic'),
    ('Cetirizine',            'Antihistamine'),
    ('Chlorpheniramine',      'Antihistamine'),
    ('Dexamethasone',         'Corticosteroid'),
    ('Prednisolone',          'Corticosteroid'),
    ('Salbutamol',            'Bronchodilator'),
    ('Metronidazole',         'Antibiotic/Antiprotozoal'),
    ('Cotrimoxazole',         'Antibiotic'),
    ('Doxycycline',           'Antibiotic'),
    ('Ceftriaxone',           'Antibiotic'),
    ('Gentamicin',            'Antibiotic'),
    ('Insulin',               'Antidiabetic'),
    ('Digoxin',               'Cardiac Glycoside'),
    ('Furosemide',            'Diuretic'),
    ('Spironolactone',        'Diuretic'),
    ('Clopidogrel',           'Antiplatelet')
ON CONFLICT (drug_name) DO NOTHING;

-- ── lab_reference_ranges ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS lab_reference_ranges (
    id          BIGSERIAL PRIMARY KEY,
    test_name   VARCHAR(300) NOT NULL UNIQUE,
    min_value   DOUBLE PRECISION NOT NULL,
    max_value   DOUBLE PRECISION NOT NULL,
    unit        VARCHAR(50),
    notes       VARCHAR(300)
);

INSERT INTO lab_reference_ranges (test_name, min_value, max_value, unit, notes) VALUES
    ('Hemoglobin',              11.5,  17.5,  'g/dL',    'Combined adult range'),
    ('Haemoglobin',             11.5,  17.5,  'g/dL',    'Combined adult range'),
    ('Hb',                      11.5,  17.5,  'g/dL',    'Combined adult range'),
    ('WBC',                     4.0,   11.0,  '10^3/uL', 'White blood cell count'),
    ('White Blood Cells',       4.0,   11.0,  '10^3/uL', NULL),
    ('Platelets',               150.0, 400.0, '10^3/uL', NULL),
    ('Platelet Count',          150.0, 400.0, '10^3/uL', NULL),
    ('Blood Glucose Fasting',   70.0,  100.0, 'mg/dL',   'FBS normal range'),
    ('FBS',                     70.0,  100.0, 'mg/dL',   'Fasting Blood Sugar'),
    ('Blood Glucose',           70.0,  140.0, 'mg/dL',   'Post-meal inclusive range'),
    ('HbA1c',                   4.0,   5.7,   '%',       'Diabetes diagnostic'),
    ('Serum Creatinine',        0.6,   1.2,   'mg/dL',   'Combined adult'),
    ('Creatinine',              0.6,   1.2,   'mg/dL',   NULL),
    ('Blood Urea',              7.0,   20.0,  'mg/dL',   NULL),
    ('Urea',                    7.0,   20.0,  'mg/dL',   NULL),
    ('Sodium',                  136.0, 145.0, 'mEq/L',   NULL),
    ('Potassium',               3.5,   5.0,   'mEq/L',   NULL),
    ('Total Bilirubin',         0.1,   1.2,   'mg/dL',   NULL),
    ('Bilirubin',               0.1,   1.2,   'mg/dL',   NULL),
    ('ALT',                     7.0,   56.0,  'U/L',     'Liver enzyme'),
    ('SGPT',                    7.0,   56.0,  'U/L',     'ALT alternate name'),
    ('AST',                     10.0,  40.0,  'U/L',     'Liver enzyme'),
    ('SGOT',                    10.0,  40.0,  'U/L',     'AST alternate name'),
    ('Total Cholesterol',       0.0,   200.0, 'mg/dL',   'Desirable < 200'),
    ('LDL',                     0.0,   100.0, 'mg/dL',   'Optimal < 100'),
    ('HDL',                     40.0,  999.0, 'mg/dL',   'Higher is better'),
    ('Triglycerides',           0.0,   150.0, 'mg/dL',   'Normal < 150'),
    ('TSH',                     0.4,   4.0,   'mIU/L',   'Thyroid stimulating hormone'),
    ('Urine Albumin',           0.0,   30.0,  'mg/g',    NULL),
    ('ESR',                     0.0,   20.0,  'mm/hr',   'Combined adult')
ON CONFLICT (test_name) DO NOTHING;
