package com.Rahul.AshaSathi.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.net.URI;
import java.net.URISyntaxException;

@Configuration
public class HerokuDataSourceConfig {

    @Bean
    public DataSource dataSource(Environment environment) {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setJdbcUrl(resolveJdbcUrl(environment));
        dataSource.setUsername(resolveUsername(environment));
        dataSource.setPassword(resolvePassword(environment));
        dataSource.setMaximumPoolSize(resolveMaximumPoolSize(environment));
        return dataSource;
    }

    private String resolveJdbcUrl(Environment environment) {
        String jdbcDatabaseUrl = trimToNull(environment.getProperty("JDBC_DATABASE_URL"));
        if (StringUtils.hasText(jdbcDatabaseUrl)) {
            return jdbcDatabaseUrl;
        }

        String databaseUrl = trimToNull(environment.getProperty("DATABASE_URL"));
        if (StringUtils.hasText(databaseUrl)) {
            return convertDatabaseUrlToJdbcUrl(databaseUrl);
        }

        String dbUrl = trimToNull(environment.getProperty("DB_URL"));
        if (StringUtils.hasText(dbUrl)) {
            return dbUrl;
        }

        return "jdbc:postgresql://localhost:5432/ashasathi";
    }

    private String resolveUsername(Environment environment) {
        String jdbcUsername = trimToNull(environment.getProperty("JDBC_DATABASE_USERNAME"));
        if (StringUtils.hasText(jdbcUsername)) {
            return jdbcUsername;
        }

        String databaseUrl = trimToNull(environment.getProperty("DATABASE_URL"));
        String databaseUrlUsername = extractUsername(databaseUrl);
        if (StringUtils.hasText(databaseUrlUsername)) {
            return databaseUrlUsername;
        }

        String dbUsername = trimToNull(environment.getProperty("DB_USERNAME"));
        if (StringUtils.hasText(dbUsername)) {
            return dbUsername;
        }

        return "postgres";
    }

    private String resolvePassword(Environment environment) {
        String jdbcPassword = trimToNull(environment.getProperty("JDBC_DATABASE_PASSWORD"));
        if (StringUtils.hasText(jdbcPassword)) {
            return jdbcPassword;
        }

        String databaseUrl = trimToNull(environment.getProperty("DATABASE_URL"));
        String databaseUrlPassword = extractPassword(databaseUrl);
        if (StringUtils.hasText(databaseUrlPassword)) {
            return databaseUrlPassword;
        }

        String dbPassword = trimToNull(environment.getProperty("DB_PASSWORD"));
        if (StringUtils.hasText(dbPassword)) {
            return dbPassword;
        }

        return "password";
    }

    private int resolveMaximumPoolSize(Environment environment) {
        String configuredPoolSize = trimToNull(environment.getProperty("spring.datasource.hikari.maximum-pool-size"));
        if (!StringUtils.hasText(configuredPoolSize)) {
            return 10;
        }

        try {
            return Integer.parseInt(configuredPoolSize);
        } catch (NumberFormatException ex) {
            return 10;
        }
    }

    private String convertDatabaseUrlToJdbcUrl(String databaseUrl) {
        if (databaseUrl.startsWith("jdbc:")) {
            return databaseUrl;
        }

        try {
            URI uri = new URI(databaseUrl);
            if (!"postgres".equalsIgnoreCase(uri.getScheme()) && !"postgresql".equalsIgnoreCase(uri.getScheme())) {
                throw new IllegalStateException("Unsupported DATABASE_URL scheme: " + uri.getScheme());
            }

            StringBuilder jdbcUrl = new StringBuilder("jdbc:postgresql://")
                    .append(uri.getHost());

            if (uri.getPort() > 0) {
                jdbcUrl.append(':').append(uri.getPort());
            }

            if (StringUtils.hasText(uri.getPath())) {
                jdbcUrl.append(uri.getPath());
            }

            if (StringUtils.hasText(uri.getQuery())) {
                jdbcUrl.append('?').append(uri.getQuery());
            }

            return jdbcUrl.toString();
        } catch (URISyntaxException ex) {
            throw new IllegalStateException("Invalid DATABASE_URL value", ex);
        }
    }

    private String extractUsername(String databaseUrl) {
        if (!StringUtils.hasText(databaseUrl)) {
            return null;
        }

        try {
            URI uri = new URI(databaseUrl);
            String userInfo = uri.getUserInfo();
            if (!StringUtils.hasText(userInfo)) {
                return null;
            }

            int separatorIndex = userInfo.indexOf(':');
            return separatorIndex >= 0 ? userInfo.substring(0, separatorIndex) : userInfo;
        } catch (URISyntaxException ex) {
            return null;
        }
    }

    private String extractPassword(String databaseUrl) {
        if (!StringUtils.hasText(databaseUrl)) {
            return null;
        }

        try {
            URI uri = new URI(databaseUrl);
            String userInfo = uri.getUserInfo();
            if (!StringUtils.hasText(userInfo)) {
                return null;
            }

            int separatorIndex = userInfo.indexOf(':');
            return separatorIndex >= 0 && separatorIndex + 1 < userInfo.length()
                    ? userInfo.substring(separatorIndex + 1)
                    : null;
        } catch (URISyntaxException ex) {
            return null;
        }
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }
}
