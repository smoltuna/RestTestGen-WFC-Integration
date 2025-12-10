# Keycloak JVM Build

Keycloak di default compila in modalità native (GraalVM), che non produce bytecode .class necessario per JaCoCo. Questa guida spiega come buildarlo in JVM mode per abilitare il code coverage.

## Build del JAR

```bash
# Clone repository
cd ~/temp  # Or any temporary directory
git clone https://github.com/keycloak/keycloak.git
cd keycloak

# Build dipendenze (~4 minuti)
./mvnw clean install -DskipTestsuite -DskipExamples -DskipTests -Dmaven.javadoc.skip=true -T 2C

# Build distribuzione JVM (IMPORTANTE: uber-jar forza JVM mode invece di native)
cd quarkus/dist
mvn clean package -DskipTests -Dquarkus.package.jar.type=uber-jar

# Estrai distribuzione
cd target
unzip -q keycloak-999.0.0-SNAPSHOT.zip
cd keycloak-999.0.0-SNAPSHOT

# Estrai .class files per JaCoCo
mkdir extracted-classes && cd extracted-classes
jar xf ../lib/quarkus/transformed-bytecode.jar
jar xf ../lib/quarkus/generated-bytecode.jar
# Risultato: 1116 file .class in org/keycloak/
```

## Setup RESTgym

```bash
# From RESTgym root directory
cd RESTgym/apis
mkdir -p keycloak/{classes,dictionaries,database,specifications}

# Copia files
cp -r extracted-classes/org keycloak/classes/
cp -r lib conf bin providers themes keycloak/
cp ../../OAS/keycloak-openapi-23.0.7.json keycloak/specifications/
```

## Docker Build & Run

```bash
# From RESTgym root directory
cd RESTgym
docker build -t restgym/keycloak -f apis/keycloak/Dockerfile .

# Test
docker run -it --rm -v $(pwd)/results:/results -e TOOL=manual -e RUN=test1 -p 8080:8080 -p 9090:9090 restgym/keycloak
```


