# STAGE 1: Build the application using Maven
FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /workspace

# Copy the Maven wrapper and pom files to leverage Docker cache
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY payment-tracker-app/pom.xml ./payment-tracker-app/
COPY payment-tracker-identity/pom.xml ./payment-tracker-identity/
COPY payment-tracker-payment/pom.xml ./payment-tracker-payment/
COPY payment-tracker-analysis/pom.xml ./payment-tracker-analysis/
COPY payment-tracker-notification/pom.xml ./payment-tracker-notification/
COPY payment-tracker-analytics/pom.xml ./payment-tracker-analytics/
COPY payment-tracker-shared-kernel/pom.xml ./payment-tracker-shared-kernel/

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy the rest of the source code
COPY . .

# Build the application, skipping tests
RUN ./mvnw clean install -DskipTests

# STAGE 2: Create the final, lean image
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copy the executable jar from the builder stage
COPY --from=builder /workspace/payment-tracker-app/target/payment-tracker-app-0.0.1-SNAPSHOT.jar app.jar

# Expose the application port
EXPOSE 8080

# Set the entrypoint to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]