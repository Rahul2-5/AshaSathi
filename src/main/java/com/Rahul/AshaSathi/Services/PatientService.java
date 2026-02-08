package com.Rahul.AshaSathi.Services;


import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import org.springframework.stereotype.Service;

import java.io.File;

@Service
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

        //  Delete photo folder if exists
        if (patient.getPhotoPath() != null) {
            File folder = new File("uploads/patients/" + id);
            if (folder.exists()) {
                for (File file : folder.listFiles()) {
                    file.delete();
                }
                folder.delete();
            }
        }

        patientRepository.delete(patient);
    }

}
