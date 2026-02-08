package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import com.Rahul.AshaSathi.Services.PatientService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
        patientService.deletePatient(id);
        return ResponseEntity.noContent().build();
    }




}
