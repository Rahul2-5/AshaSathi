package com.Rahul.AshaSathi.config;

import com.Rahul.AshaSathi.entity.DrugMaster;
import com.Rahul.AshaSathi.entity.LabReferenceRange;
import com.Rahul.AshaSathi.repository.DrugMasterRepository;
import com.Rahul.AshaSathi.repository.LabReferenceRangeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Seeds essential reference data into PostgreSQL on first startup.
 *
 * Seeds:
 *  - Common Indian prescription drugs into drug_master
 *  - Standard lab reference ranges into lab_reference_ranges
 *
 * Safe to run multiple times — skips seeding if data already exists.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class MedicalDataSeeder implements CommandLineRunner {

    private final DrugMasterRepository drugMasterRepository;
    private final LabReferenceRangeRepository labReferenceRangeRepository;

    @Override
    public void run(String... args) {
        seedDrugs();
        seedLabRanges();
    }

    private void seedDrugs() {
        List<String[]> drugs = List.of(
            // {drugName, genericName, drugClass}
            // ── Analgesics / NSAIDs ──────────────────────────────────────────────
            new String[]{"Paracetamol", "Acetaminophen", "Analgesic"},
            new String[]{"Paracetamol 500mg", "Acetaminophen", "Analgesic"},
            new String[]{"Paracetamol 650mg", "Acetaminophen", "Analgesic"},
            new String[]{"Ibuprofen", "Ibuprofen", "NSAID"},
            new String[]{"Ibuprofen 400mg", "Ibuprofen", "NSAID"},
            new String[]{"Diclofenac", "Diclofenac", "NSAID"},
            new String[]{"Diclofenac 50mg", "Diclofenac", "NSAID"},
            new String[]{"Naproxen", "Naproxen", "NSAID"},
            new String[]{"Mefenamic Acid", "Mefenamic Acid", "NSAID"},
            new String[]{"Ketorolac", "Ketorolac", "NSAID"},
            new String[]{"Tramadol", "Tramadol", "Opioid Analgesic"},
            new String[]{"Aspirin", "Aspirin", "Antiplatelet"},
            new String[]{"Aspirin 75mg", "Aspirin", "Antiplatelet"},
            new String[]{"Aspirin 150mg", "Aspirin", "Antiplatelet"},
            // ── Antibiotics ─────────────────────────────────────────────────────
            new String[]{"Amoxicillin", "Amoxicillin", "Antibiotic"},
            new String[]{"Amoxicillin 250mg", "Amoxicillin", "Antibiotic"},
            new String[]{"Amoxicillin 500mg", "Amoxicillin", "Antibiotic"},
            new String[]{"Amoxicillin Clavulanate", "Amoxicillin+Clavulanic Acid", "Antibiotic"},
            new String[]{"Augmentin", "Amoxicillin+Clavulanic Acid", "Antibiotic"},
            new String[]{"Azithromycin", "Azithromycin", "Antibiotic"},
            new String[]{"Azithromycin 250mg", "Azithromycin", "Antibiotic"},
            new String[]{"Azithromycin 500mg", "Azithromycin", "Antibiotic"},
            new String[]{"Ciprofloxacin", "Ciprofloxacin", "Antibiotic"},
            new String[]{"Ciprofloxacin 500mg", "Ciprofloxacin", "Antibiotic"},
            new String[]{"Cefixime", "Cefixime", "Antibiotic"},
            new String[]{"Cefixime 200mg", "Cefixime", "Antibiotic"},
            new String[]{"Ceftriaxone", "Ceftriaxone", "Antibiotic"},
            new String[]{"Doxycycline", "Doxycycline", "Antibiotic"},
            new String[]{"Doxycycline 100mg", "Doxycycline", "Antibiotic"},
            new String[]{"Cotrimoxazole", "Sulfamethoxazole+Trimethoprim", "Antibiotic"},
            new String[]{"Metronidazole", "Metronidazole", "Antibiotic"},
            new String[]{"Metronidazole 400mg", "Metronidazole", "Antibiotic"},
            new String[]{"Tinidazole", "Tinidazole", "Antibiotic"},
            new String[]{"Clindamycin", "Clindamycin", "Antibiotic"},
            new String[]{"Erythromycin", "Erythromycin", "Antibiotic"},
            new String[]{"Levofloxacin", "Levofloxacin", "Antibiotic"},
            new String[]{"Levofloxacin 500mg", "Levofloxacin", "Antibiotic"},
            new String[]{"Norfloxacin", "Norfloxacin", "Antibiotic"},
            new String[]{"Nitrofurantoin", "Nitrofurantoin", "Antibiotic"},
            // ── Antidiabetics ───────────────────────────────────────────────────
            new String[]{"Metformin", "Metformin", "Antidiabetic"},
            new String[]{"Metformin 500mg", "Metformin", "Antidiabetic"},
            new String[]{"Metformin 850mg", "Metformin", "Antidiabetic"},
            new String[]{"Metformin 1000mg", "Metformin", "Antidiabetic"},
            new String[]{"Glibenclamide", "Glibenclamide", "Antidiabetic"},
            new String[]{"Glipizide", "Glipizide", "Antidiabetic"},
            new String[]{"Gliclazide", "Gliclazide", "Antidiabetic"},
            new String[]{"Gliclazide 80mg", "Gliclazide", "Antidiabetic"},
            new String[]{"Glimepiride", "Glimepiride", "Antidiabetic"},
            new String[]{"Sitagliptin", "Sitagliptin", "Antidiabetic"},
            new String[]{"Voglibose", "Voglibose", "Antidiabetic"},
            new String[]{"Insulin", "Insulin", "Antidiabetic"},
            // ── Antihypertensives ───────────────────────────────────────────────
            new String[]{"Amlodipine", "Amlodipine", "Antihypertensive"},
            new String[]{"Amlodipine 5mg", "Amlodipine", "Antihypertensive"},
            new String[]{"Amlodipine 10mg", "Amlodipine", "Antihypertensive"},
            new String[]{"Losartan", "Losartan", "ARB Antihypertensive"},
            new String[]{"Losartan 25mg", "Losartan", "ARB Antihypertensive"},
            new String[]{"Losartan 50mg", "Losartan", "ARB Antihypertensive"},
            new String[]{"Telmisartan", "Telmisartan", "ARB Antihypertensive"},
            new String[]{"Telmisartan 40mg", "Telmisartan", "ARB Antihypertensive"},
            new String[]{"Enalapril", "Enalapril", "ACE Inhibitor"},
            new String[]{"Ramipril", "Ramipril", "ACE Inhibitor"},
            new String[]{"Hydrochlorothiazide", "Hydrochlorothiazide", "Diuretic"},
            new String[]{"Furosemide", "Furosemide", "Diuretic"},
            new String[]{"Atenolol", "Atenolol", "Beta Blocker"},
            new String[]{"Metoprolol", "Metoprolol", "Beta Blocker"},
            new String[]{"Nifedipine", "Nifedipine", "Antihypertensive"},
            // ── Statins / Cardiac ────────────────────────────────────────────────
            new String[]{"Atorvastatin", "Atorvastatin", "Statin"},
            new String[]{"Atorvastatin 10mg", "Atorvastatin", "Statin"},
            new String[]{"Atorvastatin 20mg", "Atorvastatin", "Statin"},
            new String[]{"Atorvastatin 40mg", "Atorvastatin", "Statin"},
            new String[]{"Rosuvastatin", "Rosuvastatin", "Statin"},
            new String[]{"Rosuvastatin 10mg", "Rosuvastatin", "Statin"},
            new String[]{"Simvastatin", "Simvastatin", "Statin"},
            new String[]{"Clopidogrel", "Clopidogrel", "Antiplatelet"},
            new String[]{"Clopidogrel 75mg", "Clopidogrel", "Antiplatelet"},
            new String[]{"Digoxin", "Digoxin", "Cardiac Glycoside"},
            // ── GI / PPI ────────────────────────────────────────────────────────
            new String[]{"Omeprazole", "Omeprazole", "Proton Pump Inhibitor"},
            new String[]{"Omeprazole 20mg", "Omeprazole", "Proton Pump Inhibitor"},
            new String[]{"Pantoprazole", "Pantoprazole", "Proton Pump Inhibitor"},
            new String[]{"Pantoprazole 40mg", "Pantoprazole", "Proton Pump Inhibitor"},
            new String[]{"Rabeprazole", "Rabeprazole", "Proton Pump Inhibitor"},
            new String[]{"Ranitidine", "Ranitidine", "H2 Blocker"},
            new String[]{"Domperidone", "Domperidone", "Antiemetic"},
            new String[]{"Ondansetron", "Ondansetron", "Antiemetic"},
            new String[]{"Ondansetron 4mg", "Ondansetron", "Antiemetic"},
            new String[]{"Metoclopramide", "Metoclopramide", "Antiemetic"},
            new String[]{"Loperamide", "Loperamide", "Antidiarrheal"},
            new String[]{"ORS Sachet", "Oral Rehydration Salts", "Electrolyte"},
            // ── Respiratory ─────────────────────────────────────────────────────
            new String[]{"Salbutamol", "Salbutamol", "Bronchodilator"},
            new String[]{"Levosalbutamol", "Levosalbutamol", "Bronchodilator"},
            new String[]{"Budesonide", "Budesonide", "Corticosteroid Inhaler"},
            new String[]{"Montelukast", "Montelukast", "Leukotriene Inhibitor"},
            new String[]{"Theophylline", "Theophylline", "Bronchodilator"},
            new String[]{"Dextromethorphan", "Dextromethorphan", "Cough Suppressant"},
            new String[]{"Ambroxol", "Ambroxol", "Mucolytic"},
            // ── Antihistamines ──────────────────────────────────────────────────
            new String[]{"Cetirizine", "Cetirizine", "Antihistamine"},
            new String[]{"Cetirizine 10mg", "Cetirizine", "Antihistamine"},
            new String[]{"Levocetirizine", "Levocetirizine", "Antihistamine"},
            new String[]{"Fexofenadine", "Fexofenadine", "Antihistamine"},
            new String[]{"Chlorpheniramine", "Chlorpheniramine", "Antihistamine"},
            // ── Vitamins / Minerals / Supplements ───────────────────────────────
            new String[]{"Iron Tablet", "Ferrous Sulfate", "Iron Supplement"},
            new String[]{"Ferrous Sulfate", "Ferrous Sulfate", "Iron Supplement"},
            new String[]{"Folic Acid", "Folic Acid", "Vitamin"},
            new String[]{"Folic Acid 5mg", "Folic Acid", "Vitamin"},
            new String[]{"Calcium Tablet", "Calcium Carbonate", "Mineral Supplement"},
            new String[]{"Calcium Carbonate", "Calcium Carbonate", "Mineral Supplement"},
            new String[]{"Vitamin D3", "Cholecalciferol", "Vitamin"},
            new String[]{"Vitamin B12", "Cyanocobalamin", "Vitamin"},
            new String[]{"Zinc", "Zinc Sulfate", "Mineral Supplement"},
            new String[]{"Multivitamin", "Multivitamin", "Supplement"},
            // ── Thyroid ─────────────────────────────────────────────────────────
            new String[]{"Levothyroxine", "Levothyroxine", "Thyroid Hormone"},
            new String[]{"Levothyroxine 25mcg", "Levothyroxine", "Thyroid Hormone"},
            new String[]{"Levothyroxine 50mcg", "Levothyroxine", "Thyroid Hormone"},
            new String[]{"Carbimazole", "Carbimazole", "Antithyroid"},
            // ── Corticosteroids ─────────────────────────────────────────────────
            new String[]{"Prednisolone", "Prednisolone", "Corticosteroid"},
            new String[]{"Prednisolone 5mg", "Prednisolone", "Corticosteroid"},
            new String[]{"Dexamethasone", "Dexamethasone", "Corticosteroid"},
            new String[]{"Hydrocortisone", "Hydrocortisone", "Corticosteroid"},
            new String[]{"Betamethasone", "Betamethasone", "Corticosteroid"},
            // ── Antifungals / Antiparasitics ────────────────────────────────────
            new String[]{"Albendazole", "Albendazole", "Anthelmintic"},
            new String[]{"Albendazole 400mg", "Albendazole", "Anthelmintic"},
            new String[]{"Mebendazole", "Mebendazole", "Anthelmintic"},
            new String[]{"Fluconazole", "Fluconazole", "Antifungal"},
            new String[]{"Itraconazole", "Itraconazole", "Antifungal"},
            new String[]{"Clotrimazole", "Clotrimazole", "Antifungal"},
            // ── Psychiatric / Neuro ─────────────────────────────────────────────
            new String[]{"Alprazolam", "Alprazolam", "Benzodiazepine"},
            new String[]{"Clonazepam", "Clonazepam", "Benzodiazepine"},
            new String[]{"Diazepam", "Diazepam", "Benzodiazepine"},
            new String[]{"Gabapentin", "Gabapentin", "Anticonvulsant"},
            new String[]{"Phenytoin", "Phenytoin", "Anticonvulsant"},
            new String[]{"Carbamazepine", "Carbamazepine", "Anticonvulsant"},
            new String[]{"Amitriptyline", "Amitriptyline", "Antidepressant"},
            new String[]{"Sertraline", "Sertraline", "SSRI Antidepressant"},
            new String[]{"Escitalopram", "Escitalopram", "SSRI Antidepressant"},
            new String[]{"Risperidone", "Risperidone", "Antipsychotic"},
            new String[]{"Olanzapine", "Olanzapine", "Antipsychotic"}
        );

        int added = 0;
        for (String[] d : drugs) {
            // Upsert: skip if name already exists (safe to re-run after adding new drugs)
            if (drugMasterRepository.findByDrugNameIgnoreCase(d[0]).isEmpty()) {
                DrugMaster drug = new DrugMaster();
                drug.setDrugName(d[0]);
                drug.setGenericName(d[1]);
                drug.setDrugClass(d[2]);
                drug.setActive(true);
                drugMasterRepository.save(drug);
                added++;
            }
        }

        log.info("Drug master seeding complete — {} new entries added.", added);
    }

    private void seedLabRanges() {
        if (labReferenceRangeRepository.count() > 0) {
            log.info("Lab reference ranges already seeded, skipping.");
            return;
        }

        List<Object[]> ranges = List.of(
            // {testName, min, max, criticalLow, criticalHigh, unit, gender}
            new Object[]{"Hemoglobin",        12.0, 17.5,  7.0,  20.0, "g/dL",  "ALL"},
            new Object[]{"Hemoglobin Female", 11.5, 15.5,  7.0,  20.0, "g/dL",  "FEMALE"},
            new Object[]{"Hemoglobin Male",   13.5, 17.5,  7.0,  20.0, "g/dL",  "MALE"},
            new Object[]{"WBC",                4.0,  11.0,  2.0,  30.0, "10^3/uL","ALL"},
            new Object[]{"Platelets",         150.0, 400.0, 50.0, 1000.0,"10^3/uL","ALL"},
            new Object[]{"Blood Sugar Fasting",70.0,  100.0, 40.0,  500.0, "mg/dL",  "ALL"},
            new Object[]{"Blood Sugar PP",    100.0, 140.0,  40.0,  500.0, "mg/dL",  "ALL"},
            new Object[]{"HbA1c",              4.0,   5.6,   2.0,   14.0, "%",      "ALL"},
            new Object[]{"Creatinine",         0.6,   1.2,   0.3,    8.0, "mg/dL",  "ALL"},
            new Object[]{"Creatinine Female",  0.5,   1.1,   0.3,    8.0, "mg/dL",  "FEMALE"},
            new Object[]{"Creatinine Male",    0.7,   1.3,   0.3,    8.0, "mg/dL",  "MALE"},
            new Object[]{"Urea",              15.0,  40.0,   5.0,  150.0, "mg/dL",  "ALL"},
            new Object[]{"Total Cholesterol",   0.0, 200.0,   0.0,  400.0, "mg/dL",  "ALL"},
            new Object[]{"LDL",                 0.0, 130.0,   0.0,  300.0, "mg/dL",  "ALL"},
            new Object[]{"HDL",                40.0, 999.0,  20.0,  999.0, "mg/dL",  "ALL"},
            new Object[]{"Triglycerides",       0.0, 150.0,   0.0,  500.0, "mg/dL",  "ALL"},
            new Object[]{"Sodium",            135.0, 145.0, 125.0,  160.0, "mEq/L",  "ALL"},
            new Object[]{"Potassium",           3.5,   5.0,   2.5,    6.5, "mEq/L",  "ALL"},
            new Object[]{"TSH",                 0.4,   4.0,   0.1,   50.0, "mIU/L",  "ALL"},
            new Object[]{"SGPT",                7.0,  56.0,   0.0,  500.0, "U/L",    "ALL"},
            new Object[]{"SGOT",               10.0,  40.0,   0.0,  500.0, "U/L",    "ALL"},
            new Object[]{"Bilirubin Total",     0.0,   1.2,   0.0,   15.0, "mg/dL",  "ALL"},
            new Object[]{"Uric Acid",           3.4,   7.0,   1.0,   15.0, "mg/dL",  "ALL"},
            new Object[]{"Calcium",             8.5,  10.5,   6.0,   13.0, "mg/dL",  "ALL"}
        );

        ranges.forEach(r -> {
            LabReferenceRange range = new LabReferenceRange();
            range.setTestName((String) r[0]);
            range.setMinValue((Double) r[1]);
            range.setMaxValue((Double) r[2]);
            range.setCriticalLow((Double) r[3]);
            range.setCriticalHigh((Double) r[4]);
            range.setUnit((String) r[5]);
            range.setGender((String) r[6]);
            labReferenceRangeRepository.save(range);
        });

        log.info("Lab reference ranges seeded with {} entries.", ranges.size());
    }
}
