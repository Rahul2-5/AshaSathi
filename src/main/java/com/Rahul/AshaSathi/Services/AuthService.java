package com.Rahul.AshaSathi.Services;


import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.LoginRequestDTO;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.JWT.JwtUtil;
import com.Rahul.AshaSathi.Repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
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


    public AuthResponse googleLogin(String email , String username) {
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


}
