package com.Rahul.AshaSathi.DTO;

public class TaskResponse {

    private Long id;
    private String title;
    private String description;
    private String status;
    private String createdDate;

    public TaskResponse(Long id, String title, String description,
                        String status, String createdDate) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.status = status;
        this.createdDate = createdDate;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getStatus() { return status; }
    public String getCreatedDate() { return createdDate; }
}
