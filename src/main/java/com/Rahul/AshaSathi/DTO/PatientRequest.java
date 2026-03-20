package com.Rahul.AshaSathi.DTO;

import java.time.LocalDate;

public class PatientRequest {

    public String patientName;
    public Integer age;
    public LocalDate dateOfBirth;
    public String gender;
    public String address;
    public String phoneNumber;
    // Optional fields sent by clients (offline sync)
    public String photoPath;
    public String clientTempId;
}
