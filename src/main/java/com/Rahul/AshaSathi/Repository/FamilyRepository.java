package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FamilyRepository extends JpaRepository<Family, Long> {
	List<Family> findAllByOrderByIdDesc();
}