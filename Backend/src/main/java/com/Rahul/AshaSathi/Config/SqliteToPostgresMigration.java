package com.Rahul.AshaSathi.Config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

@Component
public class SqliteToPostgresMigration {

    private static final Logger logger = LoggerFactory.getLogger(SqliteToPostgresMigration.class);

    private final JdbcTemplate postgresJdbc;

    @Value("${app.migration.sqlite-to-postgres.enabled:true}")
    private boolean migrationEnabled;

    @Value("${app.migration.sqlite-path:D:/Flutter_Projects/AshaSathi/Backend/data/ashasathi.db}")
    private String sqlitePath;

    public SqliteToPostgresMigration(JdbcTemplate postgresJdbc) {
        this.postgresJdbc = postgresJdbc;
    }

    private record UserImportResult(int importedCount, Map<Long, Long> userIdMap) {}

    @PostConstruct
    public void migrateIfNeeded() {
        if (!migrationEnabled) {
            logger.info("SQLite to PostgreSQL migration disabled via config.");
            return;
        }

        Path source = Path.of(sqlitePath);
        if (!Files.exists(source)) {
            logger.info("Legacy SQLite DB not found at {}. Skipping migration.", sqlitePath);
            return;
        }

        int usersCount = safeCount("users");
        int patientsCount = safeCount("patients");
        int tasksCount = safeCount("tasks");

        if (patientsCount > 0 || tasksCount > 0) {
            logger.info("PostgreSQL already has operational data (users={}, patients={}, tasks={}). " +
                            "Skipping SQLite import to avoid duplicates.",
                    usersCount, patientsCount, tasksCount);
            return;
        }

        String sqliteUrl = "jdbc:sqlite:" + sqlitePath;
        logger.info("Starting one-time data import from SQLite {} to PostgreSQL.", sqlitePath);

        try (Connection sqliteConn = DriverManager.getConnection(sqliteUrl)) {
            UserImportResult usersResult = importUsers(sqliteConn);
            int importedUsers = usersResult.importedCount();
            int importedPatients = importPatients(sqliteConn);
            int importedTasks = importTasks(sqliteConn, usersResult.userIdMap());

            resetSequences();

            logger.info("SQLite import completed. Imported users={}, patients={}, tasks={}",
                    importedUsers, importedPatients, importedTasks);
        } catch (Exception e) {
            logger.error("SQLite to PostgreSQL migration failed: {}", e.getMessage(), e);
        }
    }

    private UserImportResult importUsers(Connection sqliteConn) {
        if (!tableExists(sqliteConn, "users")) {
            logger.info("SQLite table users not found. Skipping users import.");
            return new UserImportResult(0, Map.of());
        }

        String sql = "SELECT * FROM users";
        int imported = 0;
        Map<Long, Long> userIdMap = new LinkedHashMap<>();

        try (Statement st = sqliteConn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> row = rowMap(rs);

                Long id = asLong(getAny(row, "id"));
                String email = asString(getAny(row, "email"));
                String username = asString(getAny(row, "username"));
                String password = asString(getAny(row, "password"));
                String provider = asString(getAny(row, "provider"));
                LocalDateTime createdAt = parseDateTime(getAny(row, "created_at", "createdat"));

                if (email == null || email.isBlank()) {
                    continue;
                }

                Long pgUserId = postgresJdbc.queryForObject("""
                        INSERT INTO users (email, username, password, provider, created_at)
                        VALUES (?, ?, ?, ?, ?)
                        ON CONFLICT (email)
                        DO UPDATE SET
                            username = EXCLUDED.username,
                            password = EXCLUDED.password,
                            provider = EXCLUDED.provider
                        RETURNING id
                        """, Long.class, email, username, password, provider, createdAt);

                if (id != null && pgUserId != null) {
                    userIdMap.put(id, pgUserId);
                }

                imported++;
            }
        } catch (Exception e) {
            logger.error("Failed importing users: {}", e.getMessage(), e);
        }

        return new UserImportResult(imported, userIdMap);
    }

    private int importPatients(Connection sqliteConn) {
        if (!tableExists(sqliteConn, "patients")) {
            logger.info("SQLite table patients not found. Skipping patients import.");
            return 0;
        }

        String sql = "SELECT * FROM patients";
        int imported = 0;

        try (Statement st = sqliteConn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> row = rowMap(rs);

                Long id = asLong(getAny(row, "id"));
                String patientName = asString(getAny(row, "patient_name", "patientname"));
                Integer age = asInt(getAny(row, "age"));
                LocalDate dob = parseDate(getAny(row, "date_of_birth", "dateofbirth"));
                String gender = asString(getAny(row, "gender"));
                String address = asString(getAny(row, "address"));
                String phoneNumber = asString(getAny(row, "phone_number", "phonenumber"));
                String photoPath = asString(getAny(row, "photo_path", "photopath"));
                String clientTempId = asString(getAny(row, "client_temp_id", "clienttempid", "uuid"));
                LocalDateTime createdAt = parseDateTime(getAny(row, "created_at", "createdat"));
                LocalDateTime updatedAt = parseDateTime(getAny(row, "updated_at", "updatedat"));

                if (patientName == null || patientName.isBlank()) {
                    continue;
                }

                postgresJdbc.update("""
                        INSERT INTO patients (
                            id, patient_name, age, date_of_birth, gender, address,
                            phone_number, photo_path, client_temp_id, created_at, updated_at
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT (id) DO NOTHING
                        """,
                        id, patientName, age, dob, gender, address,
                        phoneNumber, photoPath, clientTempId, createdAt, updatedAt);
                imported++;
            }
        } catch (Exception e) {
            logger.error("Failed importing patients: {}", e.getMessage(), e);
        }

        return imported;
    }

    private int importTasks(Connection sqliteConn, Map<Long, Long> userIdMap) {
        if (!tableExists(sqliteConn, "tasks")) {
            logger.info("SQLite table tasks not found. Skipping tasks import.");
            return 0;
        }

        String sql = "SELECT * FROM tasks";
        int imported = 0;

        try (Statement st = sqliteConn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> row = rowMap(rs);

                Long id = asLong(getAny(row, "id"));
                String title = asString(getAny(row, "title"));
                String description = asString(getAny(row, "description"));
                String status = asString(getAny(row, "status"));
                String createdDate = asString(getAny(row, "created_date", "createddate"));
                Long oldUserId = asLong(getAny(row, "user_id", "userid"));

                if (title == null || title.isBlank() || oldUserId == null) {
                    continue;
                }

                Long targetUserId = userIdMap.get(oldUserId);
                if (targetUserId == null) {
                    logger.warn("Skipping task id={} because mapped user id for SQLite user {} was not found.", id, oldUserId);
                    continue;
                }

                postgresJdbc.update("""
                        INSERT INTO tasks (id, title, description, status, created_date, user_id)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT (id) DO NOTHING
                        """, id, title, description, status, createdDate, targetUserId);
                imported++;
            }
        } catch (Exception e) {
            logger.error("Failed importing tasks: {}", e.getMessage(), e);
        }

        return imported;
    }

    private int safeCount(String table) {
        try {
            Integer count = postgresJdbc.queryForObject("SELECT COUNT(*) FROM " + table, Integer.class);
            return count == null ? 0 : count;
        } catch (Exception ignored) {
            return 0;
        }
    }

    private void resetSequences() {
        resetSequence("users", "id");
        resetSequence("patients", "id");
        resetSequence("tasks", "id");
    }

    private void resetSequence(String table, String column) {
        try {
            postgresJdbc.execute("""
                    SELECT setval(
                        pg_get_serial_sequence('%s', '%s'),
                        COALESCE((SELECT MAX(%s) FROM %s), 1),
                        true
                    )
                    """.formatted(table, column, column, table));
        } catch (Exception e) {
            logger.warn("Could not reset sequence for {}.{}: {}", table, column, e.getMessage());
        }
    }

    private boolean tableExists(Connection conn, String tableName) {
        try (ResultSet rs = conn.getMetaData().getTables(null, null, tableName, null)) {
            return rs.next();
        } catch (SQLException e) {
            logger.warn("Unable to check table {} in SQLite: {}", tableName, e.getMessage());
            return false;
        }
    }

    private Map<String, Object> rowMap(ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        Map<String, Object> row = new HashMap<>();
        for (int i = 1; i <= md.getColumnCount(); i++) {
            String label = md.getColumnLabel(i);
            if (label != null) {
                row.put(label.toLowerCase(Locale.ROOT), rs.getObject(i));
            }
        }
        return row;
    }

    private Object getAny(Map<String, Object> row, String... keys) {
        for (String k : keys) {
            Object val = row.get(k.toLowerCase(Locale.ROOT));
            if (val != null) {
                return val;
            }
        }
        return null;
    }

    private String asString(Object val) {
        return val == null ? null : String.valueOf(val);
    }

    private Long asLong(Object val) {
        if (val == null) {
            return null;
        }
        if (val instanceof Number n) {
            return n.longValue();
        }
        try {
            return Long.parseLong(String.valueOf(val));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Integer asInt(Object val) {
        if (val == null) {
            return null;
        }
        if (val instanceof Number n) {
            return n.intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(val));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private LocalDate parseDate(Object val) {
        if (val == null) {
            return null;
        }
        try {
            return LocalDate.parse(String.valueOf(val));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private LocalDateTime parseDateTime(Object val) {
        if (val == null) {
            return null;
        }
        String text = String.valueOf(val).trim();
        if (text.isEmpty()) {
            return null;
        }

        try {
            return LocalDateTime.parse(text);
        } catch (DateTimeParseException ignored) {
        }

        try {
            return Timestamp.valueOf(text).toLocalDateTime();
        } catch (IllegalArgumentException ignored) {
        }

        return null;
    }
}
