package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.OcrLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OcrLineRepository extends JpaRepository<OcrLine, Long> {
    List<OcrLine> findByDocumentIdOrderByLineOrder(Long documentId);
}
