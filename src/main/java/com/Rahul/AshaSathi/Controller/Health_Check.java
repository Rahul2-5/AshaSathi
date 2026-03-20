package com.Rahul.AshaSathi.Controller;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Health_Check {

    @GetMapping("/")
    public String root() {
        return "AshaSathi Backend is running";
    }

    @GetMapping("/health-check")
    public String HealthCheck(){
        return "Working";
    }

    @GetMapping("/api/test")
    public String test() {
        return "JWT WORKING!";
    }
}
