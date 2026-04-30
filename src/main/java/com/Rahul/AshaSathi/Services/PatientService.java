package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;

@Service
@Transactional
public class PatientService {

    private final PatientRepository patientRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public PatientService(PatientRepository patientRepository) {
        this.patientRepository = patientRepository;
    }

    public Patient savePatient(PatientRequest request, User user) {
        // If clientTempId is provided and a patient with that clientTempId exists,
        // return the existing patient (avoid duplicate creates from offline retries).
        if (request.clientTempId != null && !request.clientTempId.isEmpty()) {
            Patient existing = patientRepository
                    .findByClientTempIdAndUserId(request.clientTempId, user.getId())
                    .orElse(null);
            if (existing != null) {
                // update existing fields
                existing.setPatientName(request.patientName);
                existing.setAge(request.age);
                existing.setDateOfBirth(request.dateOfBirth);
                existing.setGender(request.gender);
                existing.setCaste(request.caste);
                existing.setIsPregnant(request.isPregnant);
                existing.setMonthsOfPregnancy(request.monthsOfPregnancy);
                existing.setExpectedDeliveryDate(request.expectedDeliveryDate);
                existing.setDeclinedHealthInfo(request.declinedHealthInfo);
                if (request.diseases != null) existing.setDiseases(request.diseases);
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
        patient.setCaste(request.caste);
        patient.setIsPregnant(request.isPregnant);
        patient.setMonthsOfPregnancy(request.monthsOfPregnancy);
        patient.setExpectedDeliveryDate(request.expectedDeliveryDate);
        patient.setDeclinedHealthInfo(request.declinedHealthInfo);
        patient.setDiseases(request.diseases);
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
        patient.setUser(user);

        return patientRepository.save(patient);
    }

    public void deletePatient(Long id, Long userId) {
        Patient patient = patientRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new RuntimeException("Patient not found"));

        // Legacy schema compatibility: clear dependent disease rows first if table exists.
        try {
            entityManager.createNativeQuery("DELETE FROM patient_disease WHERE patient_id = :patientId")
                    .setParameter("patientId", id)
                    .executeUpdate();
        } catch (Exception ignored) {
            // No-op: table may not exist in newer schema versions.
        }

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
    public Patient updatePatient(Long id, PatientRequest request, Long userId) {
        Patient patient = patientRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new RuntimeException("Patient not found"));

        patient.setPatientName(request.patientName);
        patient.setAge(request.age);
        patient.setDateOfBirth(request.dateOfBirth);
        patient.setGender(request.gender);
        patient.setCaste(request.caste);
        patient.setIsPregnant(request.isPregnant);
        patient.setMonthsOfPregnancy(request.monthsOfPregnancy);
        patient.setExpectedDeliveryDate(request.expectedDeliveryDate);
        patient.setDeclinedHealthInfo(request.declinedHealthInfo);
        if (request.diseases != null) patient.setDiseases(request.diseases);
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
