package com.Rahul.AshaSathi.Controller;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Health_Check {

    @org.springframework.beans.factory.annotation.Autowired
    private com.Rahul.AshaSathi.Repository.MedicalDocumentRepository docRepo;

    @GetMapping("/api/health/documents")
    public java.util.List<java.util.Map<String, Object>> getDocuments() {
        return docRepo.findAll().stream().map(doc -> {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", doc.getId());
            map.put("status", doc.getProcessingStatus() != null ? doc.getProcessingStatus().name() : null);
            map.put("error", doc.getErrorMessage());
            map.put("rawTextLength", doc.getRawText() != null ? doc.getRawText().length() : 0);
            map.put("aiSummaryLength", doc.getAiSummary() != null ? doc.getAiSummary().length() : 0);
            return map;
        }).collect(java.util.stream.Collectors.toList());
    }

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

