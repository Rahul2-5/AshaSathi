package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.Services.PatientPhotoService;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.UserRepository;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/patients")
public class PatientPhotoController {

    private final PatientPhotoService patientPhotoService;
    private final UserRepository userRepository;

    public PatientPhotoController(
            PatientPhotoService patientPhotoService,
            UserRepository userRepository
    ) {
        this.patientPhotoService = patientPhotoService;
        this.userRepository = userRepository;
    }

    @PostMapping(
            value = "/{patientId}/photo",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> uploadPhoto(
            @PathVariable Long patientId,
            @RequestPart("photo") MultipartFile photo
    ) {
        try {
            if (photo == null || photo.isEmpty()) {
                return ResponseEntity.badRequest().body("Photo file is empty");
            }

            User user = getCurrentUser();
            patientPhotoService.uploadPatientPhoto(patientId, photo, user.getId());
            return ResponseEntity.ok("Photo uploaded successfully");

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
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
