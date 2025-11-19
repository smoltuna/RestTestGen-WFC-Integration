## Dockerizing RealWorld for RESTgym ✅

This short README explains how to prepare the `realworld-backend-micronaut` API so it works with RESTgym:
- how to get a runnable JAR, 
- how to build & run the Docker image, 
- where the results are stored, 

### 1) Build the JAR (how to get the artifact)

The project's runnable fat-jar is produced by Gradle using the Shadow plugin. From the `apis/realworld-backend-micronaut/` folder run:

```bash
./gradlew shadowJar
```

After the build completes you will find the jar at:

```text
service/build/libs/realworld-backend-micronaut-<version>.jar
```

Tip: you can also use the official image that publishes a native artifact, but for RESTgym we prefer the jar to run under the JaCoCo agent.

### 2) Build the Docker image

From the project root run:

```bash
docker build -t restgym/realworld-backend-micronaut -f apis/realworld-backend-micronaut/Dockerfile .
```

You can also use `python3 build.py` (from repository root) to build all APIs/tools through RESTgym automation.

### 3) Run the image 

RESTgym uses the following environment variables to organize results inside the container:
- `API`: API slug (set in the Dockerfile to `realworld-backend-micronaut` but you can override it at runtime)
- `TOOL`: the testing tool name (e.g., `deeprest`, `restler`, or `test-tool`) — this becomes a subfolder inside `results/`
- `RUN`: integer run id (1..N) — this becomes another nested subfolder inside `results/`

```bash
docker run -d --name realworld-test \
  -p 8080:8080 -p 9090:9090 -p 12345:12345 \
  -e TOOL=test-tool -e RUN=1 \
  -v $(pwd)/results:/results \
  restgym/realworld-backend-micronaut
```

Explanation:
- Port `8080`: the API port
- Port `9090`: MITM proxy (mitmdump) runs here in reverse mode
- Port `12345`: JaCoCo TCP server port where the JaCoCo agent listens
- The `-v $(pwd)/results:/results` mapping is crucial: it makes the `/results/$API/$TOOL/$RUN` folder in the container visible on the host under `./results/`.

Note: RESTgym's `run.py` orchestrates these variables for each tool and repetition.

### RESTats

### 4) What is written into `results/`

Inside `./results/<api_slug>/<tool>/<run>/`:
- `results.db`: SQLite DB containing HTTP interaction records captured by the proxy (`store-interactions.py`).
- `code-coverage/`: JaCoCo samples created at regular intervals; you will find both `.exec` (binary) and `.csv` (human-readable) files.

How coverage is collected:
- The `collect-coverage-interval.sh` script calls JaCoCo to dump a sample of coverage from the running JVM. 
- It generates `.exec` and `.csv` files under `/results/$API/$TOOL/$RUN/code-coverage`.
- The `process_results.py` script uses the `.csv` files to compute branch/line/method coverage values.

How HTTP interactions are recorded:
- `mitmdump` runs with a `store-interactions.py` addon; this records all proxied requests/responses into the `results.db` file.

### 5) How to process results

After running tests (or tools) against the API, run:

```bash
python3 process_results.py
```

This script walks the `results/` directory, reads `results.db` and coverage samples, and produces `summary.json` files and aggregated CSVs under `./results/`.

