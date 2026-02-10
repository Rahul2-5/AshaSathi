package com.Rahul.AshaSathi.Controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import com.Rahul.AshaSathi.Services.PatientService;

@RestController
@RequestMapping("/api/patients")
@CrossOrigin(origins = "*")
public class PatientController {

    private final PatientService patientService;
    private final PatientRepository patientRepository;

    public PatientController(PatientService patientService, PatientRepository patientRepository) {
        this.patientService = patientService;
        this.patientRepository = patientRepository;
    }

    // 🔹 Create Patient
    @PostMapping
    public ResponseEntity<Patient> createPatient(
            @RequestBody PatientRequest request
    ) {
        Patient savedPatient = patientService.savePatient(request);
        return ResponseEntity.ok(savedPatient);
    }

    @GetMapping("/recent")
    public ResponseEntity<List<Patient>> getRecentPatients() {
        List<Patient> patients = patientRepository
                .findTop5ByOrderByUpdatedAtDesc();
        return ResponseEntity.ok(patients);
    }

    @GetMapping
    public List<Patient> getAllPatients() {
        return patientRepository.findAll();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePatient(@PathVariable Long id) {
        try {
            patientService.deletePatient(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            System.err.println("Delete patient error: " + e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }




}
