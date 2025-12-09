package com.Rahul.AshaSathi.JWT;


import org.springframework.stereotype.Component;

@Component
public class JwtUtil {
    private static final String SECRET_KEY = "my-super-secret-key-that-is-very-secure-and-long";
    private static final long EXPIRATION_TIME = 1000 * 60 * 60 * 24;


}
