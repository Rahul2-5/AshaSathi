package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.Services.PatientPhotoService;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/patients")
@CrossOrigin(origins = "*")
public class PatientPhotoController {

    private final PatientPhotoService patientPhotoService;

    public PatientPhotoController(PatientPhotoService patientPhotoService) {
        this.patientPhotoService = patientPhotoService;
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

            patientPhotoService.uploadPatientPhoto(patientId, photo);
            return ResponseEntity.ok("Photo uploaded successfully");

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
