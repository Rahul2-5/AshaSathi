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
        if (drugMasterRepository.count() > 0) {
            log.info("Drug master already seeded, skipping.");
            return;
        }

        List<String[]> drugs = List.of(
            // {drugName, genericName, drugClass}
            new String[]{"Paracetamol", "Acetaminophen", "Analgesic"},
            new String[]{"Paracetamol 500mg", "Acetaminophen", "Analgesic"},
            new String[]{"Ibuprofen", "Ibuprofen", "NSAID"},
            new String[]{"Amoxicillin", "Amoxicillin", "Antibiotic"},
            new String[]{"Amoxicillin 500mg", "Amoxicillin", "Antibiotic"},
            new String[]{"Metformin", "Metformin", "Antidiabetic"},
            new String[]{"Metformin 500mg", "Metformin", "Antidiabetic"},
            new String[]{"Metformin 1000mg", "Metformin", "Antidiabetic"},
            new String[]{"Amlodipine", "Amlodipine", "Antihypertensive"},
            new String[]{"Amlodipine 5mg", "Amlodipine", "Antihypertensive"},
            new String[]{"Atorvastatin", "Atorvastatin", "Statin"},
            new String[]{"Atorvastatin 10mg", "Atorvastatin", "Statin"},
            new String[]{"Atorvastatin 20mg", "Atorvastatin", "Statin"},
            new String[]{"Iron Tablet", "Ferrous Sulfate", "Iron Supplement"},
            new String[]{"Ferrous Sulfate", "Ferrous Sulfate", "Iron Supplement"},
            new String[]{"Folic Acid", "Folic Acid", "Vitamin"},
            new String[]{"Folic Acid 5mg", "Folic Acid", "Vitamin"},
            new String[]{"Calcium Tablet", "Calcium Carbonate", "Mineral Supplement"},
            new String[]{"Vitamin D3", "Cholecalciferol", "Vitamin"},
            new String[]{"Azithromycin", "Azithromycin", "Antibiotic"},
            new String[]{"Azithromycin 500mg", "Azithromycin", "Antibiotic"},
            new String[]{"Ciprofloxacin", "Ciprofloxacin", "Antibiotic"},
            new String[]{"Omeprazole", "Omeprazole", "Proton Pump Inhibitor"},
            new String[]{"Omeprazole 20mg", "Omeprazole", "Proton Pump Inhibitor"},
            new String[]{"Pantoprazole", "Pantoprazole", "Proton Pump Inhibitor"},
            new String[]{"Ranitidine", "Ranitidine", "H2 Blocker"},
            new String[]{"Cetirizine", "Cetirizine", "Antihistamine"},
            new String[]{"Levothyroxine", "Levothyroxine", "Thyroid Hormone"},
            new String[]{"Aspirin", "Aspirin", "Antiplatelet"},
            new String[]{"Aspirin 75mg", "Aspirin", "Antiplatelet"},
            new String[]{"Losartan", "Losartan", "ARB Antihypertensive"},
            new String[]{"Losartan 50mg", "Losartan", "ARB Antihypertensive"},
            new String[]{"Glibenclamide", "Glibenclamide", "Antidiabetic"},
            new String[]{"ORS Sachet", "Oral Rehydration Salts", "Electrolyte"},
            new String[]{"Albendazole", "Albendazole", "Anthelmintic"},
            new String[]{"Cotrimoxazole", "Sulfamethoxazole+Trimethoprim", "Antibiotic"},
            new String[]{"Doxycycline", "Doxycycline", "Antibiotic"},
            new String[]{"Prednisolone", "Prednisolone", "Corticosteroid"},
            new String[]{"Salbutamol", "Salbutamol", "Bronchodilator"},
            new String[]{"Diclofenac", "Diclofenac", "NSAID"}
        );

        drugs.forEach(d -> {
            DrugMaster drug = new DrugMaster();
            drug.setDrugName(d[0]);
            drug.setGenericName(d[1]);
            drug.setDrugClass(d[2]);
            drug.setActive(true);
            drugMasterRepository.save(drug);
        });

        log.info("Drug master seeded with {} entries.", drugs.size());
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
