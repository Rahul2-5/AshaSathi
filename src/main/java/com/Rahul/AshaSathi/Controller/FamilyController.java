package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.DTO.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.DTO.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.Entity.Family;
import com.Rahul.AshaSathi.Services.FamilyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*", maxAge = 3600)
public class FamilyController {

    private final FamilyService familyService;

    @PostMapping
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<FamilyRegistrationResponse> registerFamily(@RequestBody FamilyRegistrationRequest request) {
        if (request.getFamilyInfo() == null) {
            return ResponseEntity.badRequest().body(
                    new FamilyRegistrationResponse(null, "Family info is required", 0, "ERROR")
            );
        }

        if (request.getPatients() == null || request.getPatients().isEmpty()) {
            return ResponseEntity.badRequest().body(
                    new FamilyRegistrationResponse(null, "At least one patient is required", 0, "ERROR")
            );
        }

        FamilyRegistrationResponse response = familyService.registerFamily(request);

        if ("SUCCESS".equals(response.getStatus())) {
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        }

        return ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<Family> getFamily(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(familyService.getFamilyById(id));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Family API is running");
    }
}