# RestTestGen Dockerfile
# Build from RESTgym/: docker build -f tools/resttestgen/Dockerfile -t resttestgen .

# Stage 1: Build Java with Gradle
FROM gradle:8.14-jdk17 AS builder

WORKDIR /app

COPY tools/resttestgen/build.gradle* ./
COPY tools/resttestgen/src/ ./src/

RUN gradle clean build -x test

# Stage 2: Runtime (Eclipse Temurin 17 JRE - pure Java, no Python needed)
FROM eclipse-temurin:17-jre-jammy AS runtime

# No Python needed - WFC auth is now native Java

WORKDIR /app

# Copy built JAR from build stage
COPY --from=builder /app/build/libs/*-all.jar ./rtg.jar

# Create directory for WFC auth configurations
RUN mkdir -p /auth /specifications

# Copy WFC auth configuration files (for APIs that require authentication)
COPY apis/alfresco/alfresco-auth.yaml /auth/
COPY apis/flowable-process/flowable-process-auth.yaml /auth/
COPY apis/gravitee/gravitee-auth.yaml /auth/
COPY apis/keycloak/keycloak-auth.yaml /auth/
COPY apis/liferay/liferay-auth.yaml /auth/
COPY apis/nexus/nexus-auth.yaml /auth/
COPY apis/quartzmanager/quartzmanager-auth.yaml /auth/
COPY apis/realworld-backend-micronaut/realworld-backend-micronaut-auth.yaml /auth/
COPY apis/traccar/traccar-auth.yaml /auth/

# Copy all OpenAPI specifications to /specifications (flat structure like old image)
COPY apis/alfresco/specifications/*-openapi.json /specifications/
COPY apis/bezkoder/specifications/*-openapi.json /specifications/
COPY apis/blog/specifications/*-openapi.json /specifications/
COPY apis/cassandra-management-api/specifications/*-openapi.json /specifications/
COPY apis/erc20/specifications/*-openapi.json /specifications/
COPY apis/features-service/specifications/*-openapi.json /specifications/
COPY apis/flightsearchapi/specifications/*-openapi.json /specifications/
COPY apis/flowable-process/specifications/*-openapi.json /specifications/
COPY apis/genome-nexus/specifications/*-openapi.json /specifications/
COPY apis/gestaohospitalar/specifications/*-openapi.json /specifications/
COPY apis/gravitee/specifications/*-openapi.json /specifications/
COPY apis/kafka-rest/specifications/*-openapi.json /specifications/
COPY apis/keycloak/specifications/*-openapi.json /specifications/
COPY apis/languagetool/specifications/*-openapi.json /specifications/
COPY apis/liferay/specifications/*-openapi.json /specifications/
COPY apis/market/specifications/*-openapi.json /specifications/
COPY apis/microcks/specifications/*-openapi.json /specifications/
COPY apis/ncs/specifications/*-openapi.json /specifications/
COPY apis/nexus/specifications/*-openapi.json /specifications/
COPY apis/notebookmanager/specifications/*-openapi.json /specifications/
COPY apis/person-controller/specifications/*-openapi.json /specifications/
COPY apis/petclinic/specifications/*-openapi.json /specifications/
COPY apis/project-tracking-system/specifications/*-openapi.json /specifications/
COPY apis/quartzmanager/specifications/*-openapi.json /specifications/
COPY apis/realworld-backend-micronaut/specifications/*-openapi.json /specifications/
COPY apis/restcountries/specifications/*-openapi.json /specifications/
COPY apis/scs/specifications/*-openapi.json /specifications/
COPY apis/spring-kafka-producer/specifications/*-openapi.json /specifications/
COPY apis/spring-kafka-publisher/specifications/*-openapi.json /specifications/
COPY apis/traccar/specifications/*-openapi.json /specifications/
COPY apis/user-management/specifications/*-openapi.json /specifications/

# Copy config script (generates api-config.yml at runtime using env vars)
COPY tools/resttestgen/config.sh /app/config.sh
RUN chmod +x /app/config.sh

CMD ["sh", "-c", "sh /app/config.sh && while true; do java -jar rtg.jar; done"]
