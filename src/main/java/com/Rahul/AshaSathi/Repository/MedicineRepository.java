package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicineRepository extends JpaRepository<Medicine, Long> {
    List<Medicine> findByDocumentId(Long documentId);
    List<Medicine> findByDocumentIdAndVerified(Long documentId, boolean verified);
}
