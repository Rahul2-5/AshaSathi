package com.Rahul.AshaSathi.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {

    //private String token;
   private String email;
   private String username;
   private String provider;
   private Long userId;
}
