package com.Rahul.AshaSathi.JWT;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

/**
 * Utility for generating and validating JWT tokens.
 * Uses application property `app.jwt.secret` and `app.jwt.expiration-ms`.
 */
@Component
@RequiredArgsConstructor
public class JwtUtil {

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public String extractUsername(String token) {
        Map<String, Object> claims = decodePayload(token);
        if (claims == null) return null;
        Object sub = claims.get("sub");
        return sub == null ? null : String.valueOf(sub);
    }

    public boolean validateToken(String token) {
        try {
            Map<String, Object> claims = decodePayload(token);
            if (claims == null) return false;
            Object expObj = claims.get("exp");
            if (expObj == null) return true; // no exp claim -> treat as valid for now
            long expSeconds = Long.parseLong(String.valueOf(expObj));
            Date expiration = new Date(expSeconds * 1000L);
            return expiration.after(new Date());
        } catch (Exception e) {
            return false;
        }
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    private Map<String, Object> decodePayload(String token) {
        try {
            if (token == null) return null;
            String[] parts = token.split("\\.");
            if (parts.length < 2) return null;
            String payload = parts[1];
            byte[] decoded = Base64.getUrlDecoder().decode(payload.getBytes(StandardCharsets.UTF_8));
            return objectMapper.readValue(decoded, Map.class);
        } catch (Exception e) {
            return null;
        }
    }
}
