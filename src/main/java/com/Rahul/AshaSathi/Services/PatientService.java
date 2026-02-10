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
        Patient patient = new Patient();

        patient.setPatientName(request.patientName);
        patient.setAge(request.age);
        patient.setDateOfBirth(request.dateOfBirth);
        patient.setGender(request.gender);
        patient.setAddress(request.address);
        patient.setPhoneNumber(request.phoneNumber);

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
        patient.setPhoneNumber(request.phoneNumber);

        return patientRepository.save(patient);
    }

}
