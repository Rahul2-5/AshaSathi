package com.Rahul.AshaSathi.Config;

import com.Rahul.AshaSathi.JWT.JWTAuthenticationFilter;
import com.Rahul.AshaSathi.JWT.JwtUtil;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtUtil jwtUtil;

    public SecurityConfig(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    //  JWT FILTER (STATELESS)
    @Bean
    public JWTAuthenticationFilter jwtAuthenticationFilter() {
        return new JWTAuthenticationFilter(jwtUtil);
    }

    //  SECURITY CHAIN
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                //  CSRF not needed for JWT APIs
                .csrf(AbstractHttpConfigurer::disable)

                //  NO SESSION (STATELESS)
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                //  AUTH RULES
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/",
                                "/health-check",
                                "/api/test",
                                "/api/auth/**",
                                "/api/health/**",
                                "/uploads/**",
                                "/data/**"
                        ).permitAll()
                        .anyRequest().authenticated()
                )

                //  JWT FILTER
                .addFilterBefore(
                        jwtAuthenticationFilter(),
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    //  AUTH MANAGER (USED ONLY FOR LOGIN)
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }
}
