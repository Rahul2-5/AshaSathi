package com.Rahul.AshaSathi.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.Rahul.AshaSathi.Entity.Family;

@Repository
public interface FamilyRepository extends JpaRepository<Family, Long> {
	List<Family> findAllByOrderByIdDesc();
}