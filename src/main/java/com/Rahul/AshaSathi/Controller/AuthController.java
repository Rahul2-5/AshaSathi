package com.Rahul.AshaSathi.Controller;


import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.LoginRequestDTO;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Services.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/signup")
    public ResponseEntity<AuthResponse> signup(@RequestBody SignupRequestDTO request){
            return ResponseEntity.ok(authService.signup(request));

    }
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequestDTO request){
        return ResponseEntity.ok(authService.login(request));
    }

}
