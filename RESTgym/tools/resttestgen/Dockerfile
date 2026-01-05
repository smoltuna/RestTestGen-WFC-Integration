# Stage 1: Build Java with Gradle
FROM gradle:8.14-jdk17 AS builder

WORKDIR /app

COPY build.gradle* ./
COPY src/ ./src/

RUN gradle clean build -x test

# Stage 2: Runtime (Eclipse Temurin 17 JRE)
FROM eclipse-temurin:17-jre-jammy AS runtime

WORKDIR /app

# Copy built JAR from build stage
COPY --from=builder /app/build/libs/*-all.jar ./rtg.jar

# RTG_MODE: "standalone" runs once
#           "restgym" runs in loop for RESTgym orchestration
ENV RTG_MODE=standalone

ENTRYPOINT ["sh", "-c", "if [ \"$RTG_MODE\" = \"restgym\" ]; then while true; do java $JAVA_OPTS -jar rtg.jar; done; else exec java $JAVA_OPTS -jar rtg.jar; fi"]
