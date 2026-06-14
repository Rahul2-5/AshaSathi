package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.GoogleLoginRequestDTO;
import com.Rahul.AshaSathi.DTO.LoginRequestDTO;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Services.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@Slf4j
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupRequestDTO request) {
        try {
            return ResponseEntity.ok(authService.signup(request));
        } catch (RuntimeException e) {
            log.warn("Signup failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST) // 400
                    .body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO request) {
        try {
            return ResponseEntity.ok(authService.login(request));
        } catch (RuntimeException e) {
            log.warn("Login failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED) // 401
                    .body(e.getMessage());
        }
    }

    @PostMapping("/google")
    public ResponseEntity<?> googleLogin(
            @RequestBody GoogleLoginRequestDTO request
    ) {
        try {
            AuthResponse response = authService.googleLogin(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            log.warn("Google login failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED) // 401
                    .body(e.getMessage());
        }
    }

    @GetMapping("/google/client-id")
    public ResponseEntity<?> googleClientId() {
        return ResponseEntity.ok(
                java.util.Map.of("clientId", authService.getGoogleClientId())
        );
    }
}
