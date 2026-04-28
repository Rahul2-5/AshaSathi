package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.FamilyPatient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FamilyPatientRepository extends JpaRepository<FamilyPatient, Long> {
    List<FamilyPatient> findByFamilyId(Long familyId);

    List<FamilyPatient> findByFamilyIdOrderByIdAsc(Long familyId);

    void deleteByFamilyId(Long familyId);
}
