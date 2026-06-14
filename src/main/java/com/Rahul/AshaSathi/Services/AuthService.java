package com.Rahul.AshaSathi.Services;


import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.GoogleLoginRequestDTO;
import com.Rahul.AshaSathi.DTO.LoginRequestDTO;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.JWT.JwtUtil;
import com.Rahul.AshaSathi.Repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RestClient googleTokenClient;
    private final String googleClientId;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtUtil jwtUtil,
            @Value("${spring.security.oauth2.client.registration.google.client-id:}") String googleClientId
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.googleClientId = googleClientId;
        this.googleTokenClient = RestClient.builder()
                .baseUrl("https://oauth2.googleapis.com")
                .build();
    }

    public AuthResponse signup(SignupRequestDTO request){
            if(userRepository.findByEmail(request.getEmail()).isPresent()){
                throw new RuntimeException("Email already Registered");
            }

            User user = new User();
            user.setEmail(request.getEmail());
            user.setProvider("Basic Auth");
            user.setUsername(request.getUsername());
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            userRepository.save(user);
            String token = jwtUtil.generateToken(user.getEmail());
            return new AuthResponse(user.getId(),  user.getUsername(), user.getEmail() , token , "local");
    }

    public AuthResponse login(LoginRequestDTO request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("EMAIL_NOT_FOUND"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("INVALID_PASSWORD");
        }

        String token = jwtUtil.generateToken(user.getEmail());
        return new AuthResponse(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                token,
                "local"
        );
    }


    public AuthResponse googleLogin(GoogleLoginRequestDTO request) {
        if (request == null) {
            throw new RuntimeException("GOOGLE_TOKEN_REQUIRED");
        }

        Map<String, Object> tokenInfo;
        try {
            String idToken = request.getIdToken();
            String accessToken = request.getAccessToken();

            if (idToken != null && !idToken.isBlank()) {
                tokenInfo = googleTokenClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/tokeninfo")
                                .queryParam("id_token", idToken)
                                .build())
                        .retrieve()
                        .body(new ParameterizedTypeReference<>() {});
            } else if (accessToken != null && !accessToken.isBlank()) {
                tokenInfo = googleTokenClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/tokeninfo")
                                .queryParam("access_token", accessToken)
                                .build())
                        .retrieve()
                        .body(new ParameterizedTypeReference<>() {});
            } else {
                throw new RuntimeException("GOOGLE_TOKEN_REQUIRED");
            }
        } catch (Exception e) {
            throw new RuntimeException("GOOGLE_TOKEN_INVALID: " + e.getMessage());
        }

        if (tokenInfo == null) {
            throw new RuntimeException("GOOGLE_TOKEN_INVALID");
        }

        String audience = firstNonBlank(
                asString(tokenInfo.get("aud")),
                asString(tokenInfo.get("audience")),
                asString(tokenInfo.get("issued_to")),
                asString(tokenInfo.get("client_id"))
        );
        if (googleClientId != null && !googleClientId.isBlank() && !googleClientId.equals(audience)) {
            throw new RuntimeException("GOOGLE_TOKEN_AUDIENCE_INVALID");
        }

        String emailVerified = firstNonBlank(
                asString(tokenInfo.get("email_verified")),
                asString(tokenInfo.get("verified_email"))
        );
        if (!"true".equalsIgnoreCase(emailVerified)) {
            throw new RuntimeException("GOOGLE_EMAIL_NOT_VERIFIED");
        }

        String email = asString(tokenInfo.get("email"));
        if (email.isBlank()) {
            throw new RuntimeException("GOOGLE_EMAIL_MISSING");
        }

        String username = asString(tokenInfo.get("name"));
        int atIndex = email.indexOf('@');
        if (username.isBlank() && atIndex > 0) {
            username = email.substring(0, atIndex);
        }

        User user = userRepository.findByEmail(email).orElse(null);

        if(user == null){
            user = new User();
            user.setEmail(email);
            user.setUsername(username);
            user.setPassword("");
            user.setProvider("Google");
            userRepository.save(user);
        }
        String token = jwtUtil.generateToken(email);
        return new AuthResponse(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            token,
             user.getProvider()
        );

    }

    public String getGoogleClientId() {
        return googleClientId == null ? "" : googleClientId.trim();
    }

    private String asString(Object value) {
        return value == null ? "" : value.toString();
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }

        return "";
    }

}
