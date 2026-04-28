package com.Rahul.AshaSathi.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Rahul.AshaSathi.Entity.FamilyPatient;

@Repository
public interface FamilyPatientRepository extends JpaRepository<FamilyPatient, Long> {
    List<FamilyPatient> findByFamilyId(Long familyId);

    List<FamilyPatient> findByFamilyIdOrderByIdAsc(Long familyId);

    void deleteByFamilyId(Long familyId);
}