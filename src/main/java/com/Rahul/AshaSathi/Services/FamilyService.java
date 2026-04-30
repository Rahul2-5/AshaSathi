package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.DTO.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.DTO.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.DTO.FamilyDetailsResponseDTO;
import com.Rahul.AshaSathi.DTO.FamilyPatientResponseDTO;
import com.Rahul.AshaSathi.Entity.Family;
import com.Rahul.AshaSathi.Entity.FamilyPatient;
import com.Rahul.AshaSathi.Entity.Patient;
import com.Rahul.AshaSathi.Repository.FamilyPatientRepository;
import com.Rahul.AshaSathi.Repository.FamilyRepository;
import com.Rahul.AshaSathi.Repository.PatientRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.time.LocalDate;

@Service
public class FamilyService {

    private static final Logger log = LoggerFactory.getLogger(FamilyService.class);

    private final FamilyRepository familyRepository;
    private final FamilyPatientRepository patientRepository;
    private final PatientRepository mainPatientRepository;
    private final ObjectMapper objectMapper;

    public FamilyService(FamilyRepository familyRepository,
                         FamilyPatientRepository patientRepository,
                         PatientRepository mainPatientRepository,
                         ObjectMapper objectMapper) {
        this.familyRepository = familyRepository;
        this.patientRepository = patientRepository;
        this.mainPatientRepository = mainPatientRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public FamilyRegistrationResponse registerFamily(FamilyRegistrationRequest request) {
        try {
            Family family = new Family();
            family.setHeadOfFamily(request.getFamilyInfo().getHeadOfFamily());
            family.setNumberOfMembers(request.getFamilyInfo().getNumberOfMembers());
            family.setFamilyAddress(request.getFamilyInfo().getFamilyAddress());

            Family savedFamily = familyRepository.save(family);
            int patientCount = 0;

            if (request.getPatients() != null) {
                for (var patientDto : request.getPatients()) {
                    FamilyPatient patient = new FamilyPatient();
                    patient.setFamily(savedFamily);
                    patient.setPatientName(patientDto.getPatientName());
                    patient.setAge(patientDto.getAge());
                    patient.setDateOfBirth(patientDto.getDateOfBirth());
                    patient.setGender(patientDto.getGender());
                    patient.setCaste(patientDto.getCaste());
                    patient.setAddress(patientDto.getAddress());
                    patient.setPhoneNumber(patientDto.getPhoneNumber());
                    patient.setIsPregnant(Boolean.TRUE.equals(patientDto.getIsPregnant()));
                    patient.setMonthsOfPregnancy(patientDto.getMonthsOfPregnancy());
                    patient.setExpectedDeliveryDate(patientDto.getExpectedDeliveryDate());
                    patient.setPhotoPath(patientDto.getPhotoPath());
                    patient.setDeclinedHealthInfo(Boolean.TRUE.equals(patientDto.getDeclinedHealthInfo()));
                    patient.setNotes(patientDto.getNotes());

                    if (patientDto.getDiseases() != null) {
                        try {
                            patient.setDiseases(objectMapper.writeValueAsString(patientDto.getDiseases()));
                        } catch (Exception e) {
                            patient.setDiseases("{}");
                        }
                    } else {
                        patient.setDiseases("{}");
                    }

                    patientRepository.save(patient);

                    Patient mainPatient = new Patient();
                    mainPatient.setPatientName(patientDto.getPatientName());
                    mainPatient.setAge(patientDto.getAge());
                    mainPatient.setDateOfBirth(patientDto.getDateOfBirth() == null ? null : java.time.LocalDate.parse(patientDto.getDateOfBirth()));
                    mainPatient.setGender(patientDto.getGender());
                    mainPatient.setCaste(patientDto.getCaste());
                    mainPatient.setIsPregnant(patientDto.getIsPregnant());
                    mainPatient.setMonthsOfPregnancy(patientDto.getMonthsOfPregnancy());
                    if (patientDto.getExpectedDeliveryDate() != null && !patientDto.getExpectedDeliveryDate().isBlank()) {
                        mainPatient.setExpectedDeliveryDate(LocalDate.parse(patientDto.getExpectedDeliveryDate()));
                    }
                    mainPatient.setDeclinedHealthInfo(patientDto.getDeclinedHealthInfo());
                    mainPatient.setDiseases(patientDto.getDiseases() == null ? "{}" : objectMapper.writeValueAsString(patientDto.getDiseases()));
                    mainPatient.setAddress(patientDto.getAddress());
                    mainPatient.setDescription(patientDto.getNotes());
                    mainPatient.setPhoneNumber(patientDto.getPhoneNumber());
                    mainPatient.setPhotoPath(patientDto.getPhotoPath());
                    mainPatient.setClientTempId("family-" + savedFamily.getId() + "-" + patientCount + "-" + java.util.UUID.randomUUID());
                    mainPatientRepository.save(mainPatient);

                    patientCount++;
                }
            }

            return FamilyRegistrationResponse.builder()
                    .familyId(savedFamily.getId())
                    .message("Family registered successfully")
                    .patientCount(patientCount)
                    .status("SUCCESS")
                    .build();
        } catch (Exception e) {
            log.error("Error registering family", e);
            return FamilyRegistrationResponse.builder()
                    .message("Error: " + e.getMessage())
                    .status("ERROR")
                    .patientCount(0)
                    .build();
        }
    }

    public Family getFamilyById(Long familyId) {
        return familyRepository.findById(familyId)
                .orElseThrow(() -> new RuntimeException("Family not found with id: " + familyId));
    }

    @Transactional(readOnly = true)
    public List<FamilyDetailsResponseDTO> getAllFamilies() {
        return familyRepository.findAllByOrderByIdDesc()
                .stream()
                .map(this::mapFamilyToDetails)
                .toList();
    }

    @Transactional(readOnly = true)
    public FamilyDetailsResponseDTO getFamilyDetailsById(Long familyId) {
        Family family = familyRepository.findById(familyId)
                .orElseThrow(() -> new RuntimeException("Family not found with id: " + familyId));

        return mapFamilyToDetails(family);
    }

    @Transactional
    public void deleteFamilyById(Long familyId) {
        if (!familyRepository.existsById(familyId)) {
            throw new RuntimeException("Family not found with id: " + familyId);
        }

        patientRepository.deleteByFamilyId(familyId);
        mainPatientRepository.deleteByClientTempIdStartingWith("family-" + familyId + "-");
        familyRepository.deleteById(familyId);
        log.info("Deleted family {} and linked patients", familyId);
    }

    private FamilyDetailsResponseDTO mapFamilyToDetails(Family family) {
        List<FamilyPatientResponseDTO> patients = patientRepository
                .findByFamilyIdOrderByIdAsc(family.getId())
                .stream()
                .map(this::mapPatientToResponse)
                .toList();

        return FamilyDetailsResponseDTO.builder()
                .id(family.getId())
                .headOfFamily(family.getHeadOfFamily())
                .numberOfMembers(family.getNumberOfMembers())
                .familyAddress(family.getFamilyAddress())
                .patients(patients)
                .build();
    }

    private FamilyPatientResponseDTO mapPatientToResponse(FamilyPatient patient) {
        return FamilyPatientResponseDTO.builder()
                .id(patient.getId())
                .patientName(patient.getPatientName())
                .age(patient.getAge())
                .dateOfBirth(patient.getDateOfBirth())
                .gender(patient.getGender())
                .caste(patient.getCaste())
                .address(patient.getAddress())
                .phoneNumber(patient.getPhoneNumber())
                .isPregnant(patient.getIsPregnant())
                .monthsOfPregnancy(patient.getMonthsOfPregnancy())
                .expectedDeliveryDate(patient.getExpectedDeliveryDate())
                .photoPath(patient.getPhotoPath())
                .diseases(parseDiseasesMap(patient.getDiseases()))
                .declinedHealthInfo(patient.getDeclinedHealthInfo())
                .notes(patient.getNotes())
                .build();
    }

    private Map<String, Boolean> parseDiseasesMap(String diseasesJson) {
        if (diseasesJson == null || diseasesJson.isBlank()) {
            return Map.of();
        }

        try {
            return objectMapper.readValue(diseasesJson, new TypeReference<Map<String, Boolean>>() {});
        } catch (Exception e) {
            log.warn("Failed to parse diseases JSON for family patient: {}", e.getMessage());
            return Map.of();
        }
    }
}