# Add Patient Wizard - Required Dependencies

## Flutter pubspec.yaml Additions

Add these to your existing pubspec.yaml:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.1.0
  
  # Freezed for immutable models
  freezed_annotation: ^2.4.0
  
  # HTTP client (should already exist)
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  freezed: ^2.4.0
  riverpod_generator: ^2.3.0
```

## Installation Commands

```bash
# Get dependencies
flutter pub get

# Generate Freezed models and Riverpod code
dart run build_runner build

# Clean and rebuild if needed
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Maven Dependencies for Spring Boot

The following are already configured in pom.xml. Verify they exist:

```xml
<!-- Spring Data JPA -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- Lombok for @Data, @Builder, etc -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>

<!-- SLF4J included in Spring Boot starter -->

<!-- Jackson for JSON serialization (auto-included) -->
```

## IDE Configuration

### For Android Studio / IntelliJ IDEA:

1. Enable Annotations Processing:
   ```
   Settings → Build, Execution, Deployment → 
   Compiler → Annotation Processors → Enable annotation processing
   ```

2. Install Freezed plugin (optional but recommended):
   ```
   Settings → Plugins → Search "Freezed" → Install
   ```

## Application Properties for Spring Boot

Update `application.properties`:

```properties
# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.community.dialect.SQLiteDialect

# SQLite Connection
spring.datasource.url=jdbc:sqlite:ashasathi.db
spring.datasource.driver-class-name=org.sqlite.JDBC

# Jackson JSON processing
spring.jackson.serialization.write-dates-as-timestamps=false
spring.jackson.deserialization.fail-on-unknown-properties=false

# Logging
logging.level.com.Rahul.AshaSathi=DEBUG
logging.level.org.springframework=WARN
```

## Verification

After installation, verify everything is set up:

```bash
# Flutter
flutter doctor

# Check dependencies are resolved
flutter pub get

# Build runner ready
dart run build_runner build --help

# Spring Boot build
mvn clean install -DskipTests
```

All dependencies are now configured for the Add Patient Wizard implementation!
