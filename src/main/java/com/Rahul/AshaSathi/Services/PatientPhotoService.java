package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class PatientPhotoService {

    private final PatientRepository patientRepository;

    // ✅ ABSOLUTE SAFE PATH (inside project root)
    private static final String UPLOAD_DIR =
            System.getProperty("user.dir") + "/uploads/patients/";

    public PatientPhotoService(PatientRepository patientRepository) {
        this.patientRepository = patientRepository;
    }

    public void uploadPatientPhoto(
            Long patientId,
            MultipartFile file
    ) throws IOException {

        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new RuntimeException("Patient not found"));

        // 📂 Ensure directory exists
        Path patientDir = Paths.get(UPLOAD_DIR, patientId.toString());
        File dir = patientDir.toFile();
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IOException("Failed to create upload directory");
        }

        // 🖼 Save file
        Path filePath = patientDir.resolve("profile.jpg");
        file.transferTo(filePath.toFile());

        // 💾 Save RELATIVE path in DB (best practice)
        patient.setPhotoPath("/uploads/patients/" + patientId + "/profile.jpg");
        patientRepository.save(patient);
    }
}
