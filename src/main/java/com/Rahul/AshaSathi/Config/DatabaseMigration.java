package com.Rahul.AshaSathi.Config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class DatabaseMigration {
    private static final Logger logger = LoggerFactory.getLogger(DatabaseMigration.class);

    private final JdbcTemplate jdbcTemplate;

    public DatabaseMigration(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostConstruct
    public void ensureClientTempIdColumn() {
        try {
            List<Map<String, Object>> cols = jdbcTemplate.queryForList("PRAGMA table_info('patients')");
            boolean found = cols.stream().anyMatch(m -> "client_temp_id".equalsIgnoreCase((String) m.get("name")));
            if (!found) {
                logger.info("Adding column client_temp_id to patients table");
                jdbcTemplate.execute("ALTER TABLE patients ADD COLUMN client_temp_id VARCHAR");
            }

            // Create unique index if not exists (SQLite supports CREATE UNIQUE INDEX IF NOT EXISTS)
            logger.info("Ensuring unique index on client_temp_id");
            jdbcTemplate.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_client_temp_id ON patients(client_temp_id)");
        } catch (Exception e) {
            logger.warn("Database migration for client_temp_id failed: {}", e.getMessage());
        }
    }
}
