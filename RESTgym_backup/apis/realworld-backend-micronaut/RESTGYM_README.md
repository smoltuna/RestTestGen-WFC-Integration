# RealWorld Backend Micronaut

## Build JAR

```bash
cd apis/realworld-backend-micronaut
./gradlew shadowJar
```

Il JAR si trova in `service/build/libs/realworld-backend-micronaut-<version>.jar`

## Docker

```bash
# Build
docker build -t restgym/realworld-backend-micronaut -f apis/realworld-backend-micronaut/Dockerfile .

# Run
docker run -d -p 8080:8080 -p 9090:9090 \
  -e TOOL=test-tool -e RUN=1 \
  -v $(pwd)/results:/results \
  restgym/realworld-backend-micronaut
```


