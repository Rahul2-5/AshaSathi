package com.Rahul.AshaSathi.controller;

import com.Rahul.AshaSathi.dto.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.dto.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.dto.FamilyDetailsResponseDTO;
import com.Rahul.AshaSathi.service.FamilyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ============================================
 * FAMILY API CONTROLLER
 * ============================================
 * REST API endpoints for family management
 */
@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*", maxAge = 3600)
public class FamilyController {
    
    private final FamilyService familyService;
    
    /**
     * POST /api/families
     * Register a new family with multiple patients
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<FamilyRegistrationResponse> registerFamily(
            @RequestBody FamilyRegistrationRequest request) {
        
        log.info("Received family registration request for: {}", 
                request.getFamilyInfo().getHeadOfFamily());
        
        try {
            // Validate request
            if (request.getFamilyInfo() == null) {
                return ResponseEntity.badRequest()
                        .body(new FamilyRegistrationResponse(
                            null,
                            "Family info is required",
                            0,
                            "ERROR"
                        ));
            }
            
            if (request.getPatients() == null || request.getPatients().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new FamilyRegistrationResponse(
                            null,
                            "At least one patient is required",
                            0,
                            "ERROR"
                        ));
            }
            
            // Register family
            FamilyRegistrationResponse response = familyService.registerFamily(request);
            
            if ("SUCCESS".equals(response.getStatus())) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                return ResponseEntity.badRequest().body(response);
            }
            
        } catch (Exception e) {
            log.error("Error during family registration: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new FamilyRegistrationResponse(
                        null,
                        "Internal server error: " + e.getMessage(),
                        0,
                        "ERROR"
                    ));
        }
    }

    /**
     * GET /api/families
     * Retrieve all families
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<List<FamilyDetailsResponseDTO>> getFamilies() {
        List<FamilyDetailsResponseDTO> families = familyService.getAllFamilies();
        return ResponseEntity.ok(families);
    }
    
    /**
     * GET /api/families/{id}
     * Retrieve a family by ID
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<FamilyDetailsResponseDTO> getFamily(@PathVariable Long id) {
        try {
            FamilyDetailsResponseDTO family = familyService.getFamilyDetailsById(id);
            return ResponseEntity.ok(family);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * DELETE /api/families/{id}
     * Delete a family by ID
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN', 'ASHA')")
    public ResponseEntity<String> deleteFamily(@PathVariable Long id) {
        try {
            familyService.deleteFamilyById(id);
            return ResponseEntity.ok("Family deleted successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            log.error("Failed to delete family {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to delete family");
        }
    }
    
    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Family API is running");
    }
}
