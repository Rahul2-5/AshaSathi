package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.DrugMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DrugMasterRepository extends JpaRepository<DrugMaster, Long> {
    Optional<DrugMaster> findByDrugNameIgnoreCase(String drugName);

    @Query("SELECT d FROM DrugMaster d WHERE d.active = true")
    List<DrugMaster> findAllActiveDrugs();
}
