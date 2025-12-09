package com.Rahul.AshaSathi.Services;


import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.LoginRequestDTO;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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
            //String token =
            return new AuthResponse(user.getEmail() , user.getUsername() ,"local" ,user.getId() );
    }

    public AuthResponse login(LoginRequestDTO request){
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email Not Found"));

        if(!passwordEncoder.matches(request.getPassword(), user.getPassword())){
                throw new RuntimeException("Invalid Credentials");
        }
        return new AuthResponse(user.getEmail() , user.getUsername() ,"Local" , user.getId() );

    }



}
