package com.Rahul.AshaSathi.Services;


import com.Rahul.AshaSathi.DTO.AuthResponse;
import com.Rahul.AshaSathi.DTO.SignupRequestDTO;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final UserRepository userRepository;


    public AuthService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public AuthResponse signup(SignupRequestDTO request){
            if(userRepository.findByEmail(request.getEmail()).isPresent()){
                throw new RuntimeException("Email already Registered");
            }

            User user = new User();
            user.setEmail(request.getEmail());
            user.setProvider("Basic Auth");
            user.setUsername(request.getUsername());
            user.setPassword(request.getPassword());
            userRepository.save(user);
            return new AuthResponse(user.getEmail() , user.getUsername() ,user.getId() , );

    }




}
