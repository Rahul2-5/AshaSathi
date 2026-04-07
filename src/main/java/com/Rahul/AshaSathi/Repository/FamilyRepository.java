package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FamilyRepository extends JpaRepository<Family, Long> {
}