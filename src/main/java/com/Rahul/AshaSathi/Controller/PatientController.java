package com.Rahul.AshaSathi.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.Rahul.AshaSathi.DTO.PatientRequest;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import com.Rahul.AshaSathi.Repository.UserRepository;
import com.Rahul.AshaSathi.Services.PatientService;

@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;
    private final PatientRepository patientRepository;
    private final UserRepository userRepository;

    public PatientController(
            PatientService patientService,
            PatientRepository patientRepository,
            UserRepository userRepository
    ) {
        this.patientService = patientService;
        this.patientRepository = patientRepository;
        this.userRepository = userRepository;
    }

    // 🔹 Create Patient
    @PostMapping
    public ResponseEntity<Patient> createPatient(
            @RequestBody PatientRequest request
    ) {
        User user = getCurrentUser();
        Patient savedPatient = patientService.savePatient(request, user);
        return ResponseEntity.ok(savedPatient);
    }

    @GetMapping("/recent")
    public ResponseEntity<List<Patient>> getRecentPatients() {
        User user = getCurrentUser();
        List<Patient> patients = patientRepository
                .findTop5ByUserIdOrderByUpdatedAtDesc(user.getId());
        return ResponseEntity.ok(patients);
    }

    @GetMapping
    public List<Patient> getAllPatients() {
        User user = getCurrentUser();
        return patientRepository.findByUserId(user.getId());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Patient> updatePatient(
            @PathVariable Long id,
            @RequestBody PatientRequest request
    ) {
        User user = getCurrentUser();
        Patient updated = patientService.updatePatient(id, request, user.getId());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePatient(@PathVariable Long id) {
        try {
            User user = getCurrentUser();
            patientService.deletePatient(id, user.getId());
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            System.err.println("Delete patient error: " + e.getMessage());
            if (e.getMessage() != null && e.getMessage().contains("Patient not found")) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
    }




    private User getCurrentUser() {
        Authentication auth =
                SecurityContextHolder.getContext().getAuthentication();

        if (auth == null || auth.getPrincipal() == null) {
            throw new RuntimeException("Unauthenticated request");
        }

        String email = auth.getPrincipal().toString();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
