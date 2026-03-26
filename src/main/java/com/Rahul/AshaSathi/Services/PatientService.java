package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;

@Service
@Transactional
public class PatientService {

    private final PatientRepository patientRepository;

    public PatientService(PatientRepository patientRepository) {
        this.patientRepository = patientRepository;
    }

    public Patient savePatient(PatientRequest request) {
        // If clientTempId is provided and a patient with that clientTempId exists,
        // return the existing patient (avoid duplicate creates from offline retries).
        if (request.clientTempId != null && !request.clientTempId.isEmpty()) {
            Patient existing = patientRepository.findAll().stream()
                    .filter(p -> request.clientTempId.equals(p.getClientTempId()))
                    .findFirst()
                    .orElse(null);
            if (existing != null) {
                // update existing fields
                existing.setPatientName(request.patientName);
                existing.setAge(request.age);
                existing.setDateOfBirth(request.dateOfBirth);
                existing.setGender(request.gender);
                existing.setAddress(request.address);
                existing.setDescription(request.description);
                existing.setPhoneNumber(request.phoneNumber);
                if (request.photoPath != null) existing.setPhotoPath(request.photoPath);
                if (request.caste != null) existing.setCaste(request.caste);
                if (request.isPregnant != null) existing.setIsPregnant(request.isPregnant);
                if (request.monthsOfPregnancy != null) existing.setMonthsOfPregnancy(request.monthsOfPregnancy);
                if (request.expectedDeliveryDate != null) existing.setExpectedDeliveryDate(request.expectedDeliveryDate);
                if (request.medicalConditions != null) existing.setMedicalConditions(request.medicalConditions);
                return patientRepository.save(existing);
            }
        }

        Patient patient = new Patient();

        patient.setPatientName(request.patientName);
        patient.setAge(request.age);
        patient.setDateOfBirth(request.dateOfBirth);
        patient.setGender(request.gender);
        patient.setAddress(request.address);
        patient.setDescription(request.description);
        patient.setPhoneNumber(request.phoneNumber);
        if (request.photoPath != null) patient.setPhotoPath(request.photoPath);
        if (request.clientTempId != null) patient.setClientTempId(request.clientTempId);
        if (request.caste != null) patient.setCaste(request.caste);
        if (request.isPregnant != null) patient.setIsPregnant(request.isPregnant);
        if (request.monthsOfPregnancy != null) patient.setMonthsOfPregnancy(request.monthsOfPregnancy);
        if (request.expectedDeliveryDate != null) patient.setExpectedDeliveryDate(request.expectedDeliveryDate);
        if (request.medicalConditions != null) patient.setMedicalConditions(request.medicalConditions);

        return patientRepository.save(patient);
    }

    public void deletePatient(Long id) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Patient not found"));

        deletePatientFiles(id, patient.getPhotoPath());
        patientRepository.delete(patient);
    }

    private void deletePatientFiles(Long id, String photoPath) {
        if (photoPath == null) return;

        File folder = new File("uploads/patients/" + id);
        if (folder.exists()) {
            File[] files = folder.listFiles();
            if (files != null) {
                for (File file : files) {
                    file.delete();
                }
            }
            folder.delete();
        }
    }

    @Transactional
    public Patient updatePatient(Long id, PatientRequest request) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Patient not found"));

        patient.setPatientName(request.patientName);
        patient.setAge(request.age);
        patient.setDateOfBirth(request.dateOfBirth);
        patient.setGender(request.gender);
        patient.setAddress(request.address);
        patient.setDescription(request.description);
        patient.setPhoneNumber(request.phoneNumber);
        if (request.caste != null) patient.setCaste(request.caste);
        if (request.isPregnant != null) patient.setIsPregnant(request.isPregnant);
        if (request.monthsOfPregnancy != null) patient.setMonthsOfPregnancy(request.monthsOfPregnancy);
        if (request.expectedDeliveryDate != null) patient.setExpectedDeliveryDate(request.expectedDeliveryDate);
        if (request.medicalConditions != null) patient.setMedicalConditions(request.medicalConditions);

        return patientRepository.save(patient);
    }

}
