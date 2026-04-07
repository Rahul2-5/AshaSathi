package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.FamilyPatient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FamilyPatientRepository extends JpaRepository<FamilyPatient, Long> {
    List<FamilyPatient> findByFamilyId(Long familyId);
}