package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FamilyRepository extends JpaRepository<Family, Long> {
	List<Family> findAllByOrderByIdDesc();
}
