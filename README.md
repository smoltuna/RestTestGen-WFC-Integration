# RESTTestGen + WFC Collaborative Integration, Reporting, and Benchmark Curation

## Joint Academic Project

All engineering, infrastructure, and experimental work in this repository was developed jointly as a collaborative academic project by **Simone Xiao** and **Edoardo Bazzotti**.

This repository combines two complementary thesis tracks developed together at the University of Verona (LM-32, Academic Year 2024/2025):

1. WFC Authentication integration and evaluation in RestTestGen.
2. WFC report integration, fault categorization, and benchmark curation for a shared API dataset.

The thesis source is available in [TesiLatex/tesi.tex](TesiLatex/tesi.tex).

## Project Overview

This project delivers four connected outcomes that make REST API testing output more standardized, comparable, and actionable:

1. REST API benchmark curation: research, selection, and integration of 17 real-world containerized APIs.
2. Native WFC Authentication support in RestTestGen, including dynamic token-based flows.
3. WFC fault categorization (F100, F102, F203) mapped from existing oracle failures.
4. WFC-compliant JSON report generation for cross-tool comparison and CI/CD-friendly automation.

## Why This Matters

The REST API testing ecosystem is still fragmented:

- tools output incompatible formats, making systematic comparisons difficult;
- failure semantics are often missing (fail/error without a shared fault meaning);
- benchmark selection is inconsistent across studies.

There is also a strong authentication gap in literature:

- among 23 fuzzers surveyed, 12 support only static authentication;
- roughly the other half does not support authentication at all;
- only 6 support dynamic authentication (runtime token retrieval);
- even among those 6, many rely on custom Python scripts tied to one tool.

The result is poor portability and weaker reproducibility. WFC Authentication addresses this by introducing a shared, declarative, tool-agnostic configuration format.

## Why WFC, Why Now

- WFC Authentication was introduced by the EvoMaster research group in September 2025.
- Before this collaborative project, EvoMaster was the only fuzzer with native support.
- This project adds native WFC support to RestTestGen.
- Schemathesis, one of the most popular fuzzers on GitHub, has recently announced WFC support.

This positions RestTestGen among the earliest tools entering the WFC ecosystem and highlights strong momentum around the standard.

## What We Built

### 1) Benchmark Research, Selection, and Curation

- 41 candidate APIs investigated from GitHub, curated OpenAPI lists, and enterprise OSS sources.
- 17 APIs integrated into this repository dataset, 24 rejected with documented technical reasons.
- Selection criteria included Java compatibility, OpenAPI quality, Docker reproducibility, and runtime stability.
- Final benchmark spans broad domains (IAM, BPM, API management, tracking, healthcare, finance, social, and more).
- Structural range is wide (from very small APIs to large enterprise interfaces).

### 2) Dockerization and Observability Infrastructure

- Per-API Dockerization with Java runtime compatibility and startup health checks.
- JaCoCo instrumentation for code coverage.
- mitmproxy integration for full HTTP interaction capture.
- API-specific auth configs, dictionaries, and setup scripts integrated into the repository layout.

### 3) WFC Authentication Integration in RestTestGen

Implemented native Java components:

- WfcAuthHandler: parses auth.yaml, executes signup/login requests, extracts tokens.
- WfcAuthInfo: tracks token state, expiry, retries, and fallback mode.

Supported flows:

- Basic authentication (fixed headers).
- JWT and OAuth2 ROPC login endpoint flows.
- signupEndpoint extension for APIs that require registration before login.

Robustness behavior:

- automatic token refresh;
- controlled fallback to unauthenticated mode after repeated failures, so campaigns continue instead of terminating early.

### 4) WFC Fault Categorization Mapping

Existing oracles were extended to enrich failure outputs with WFC categories without changing verdict logic:

| Oracle | Condition | WFC Category | Meaning |
| --- | --- | --- | --- |
| StatusCodeOracle | HTTP 5xx observed | F100 | Server error |
| ErrorStatusCodeOracle | 2xx on invalid input | F102 | Validation/schema bypass |
| ErrorStatusCodeOracle | 5xx on invalid input | F100 | Server error during error fuzzing |
| MassAssignmentOracle | Protected field persisted | F203 | Mass assignment vulnerability |

A conservative fallback also classifies uncaptured HTTP 5xx as F100, ensuring server errors are not silently dropped.

### 5) WFC-Compliant Report Generation

- Implemented WfcReportWriter to generate JSON output aligned with WFC schema v0.2.0.
- Integrated at end-of-session reporting with minimal invasiveness to existing orchestration.
- Output is parseable, comparable, and suitable for automated pipelines.

## Dataset Scope and Context

- Total curated dataset: 17 containerized APIs.

### Complete API List (17)

- alfresco
- bezkoder
- cassandra-management-api
- erc20
- flightsearchapi
- flowable-process
- gestaohospitalar
- gravitee
- kafka-rest
- keycloak
- nexus
- notebookmanager
- petclinic
- quartzmanager
- realworld-backend-micronaut
- spring-kafka-publisher
- traccar

### APIs with WFC Authentication Configurations (9)

- alfresco
- flightsearchapi
- flowable-process
- gravitee
- keycloak
- nexus
- quartzmanager
- realworld-backend-micronaut
- traccar

### Why 9 Auth APIs Is Significant

For auth-focused experimental studies, 9 APIs is strong relative to typical literature baselines:

- early RESTler evaluation: 2 APIs;
- early EvoMaster evaluation: 3 APIs;
- APIRL and Morest (ICSE/AAAI context): around 6 APIs;
- this collaborative project: 9 auth-enabled APIs, plus 17 curated APIs overall.

## Experimental Highlights

### A) Authentication Impact (WFC Auth vs no-auth)

Large effects on fully protected APIs:

- Flowable: 0 -> 1410 faults
- Traccar: 0 -> 289 faults
- Keycloak: 0 -> 698 faults
- QuartzManager: 0 -> 286 faults

Substantial gains on partially public APIs:

- Alfresco: 65 -> 296 faults (+355%)
- RealWorld: 133 -> 471 faults (+254%)

Nexus qualitative shift:

- total faults decreased (99 -> 30),
- but severe F100 increased (6 -> 30),
- weaker F102 disappeared (93 -> 0).

This shows that category-level analysis is essential; total fault counts alone can be misleading.

### B) WFC Reporting and Categorization Track

- Baseline campaign: 17 APIs launched, 16 completed (Gravitee excluded due to OOM).
- 33461 faults detected overall.
- Distribution: 70% F100, 30% F102.
- Mean status-code coverage: 48.7%.

Mutation-testing summary (10 APIs, 5 mutants):

- M1, M2, M5: 100% kill rate.
- M3: 78% kill rate.
- M4: 70% kill rate.

These results provide evidence that the semantic categorization pipeline is sensitive to regressions and robust enough for comparative experimentation.

## Repository Layout

- `apis/`: API Dockerfiles and dataset assets.
- `tools/resttestgen/`: RestTestGen source, configs, and runners.
- `OAS/`: OpenAPI assets used in the project.
- `TesiLatex/`: thesis sources and manuscript materials.

## Quick Start (Standalone: API Containers + RestTestGen)

This quick start intentionally uses only API Dockerfiles plus RestTestGen.

Important: `apiUnderTest` must match a directory in `tools/resttestgen/apis` (for example `keycloak`, `petclinic`, `flowable-rest`, `realworld`).

1. Create a dedicated Docker bridge network (one-time setup).

```bash
docker network create rtg-network 2>/dev/null || true
```

2. Build and run one API container on that network (example: keycloak).

```bash
cd <project-root>

docker build -f apis/keycloak/Dockerfile -t keycloak-api .
docker rm -f keycloak 2>/dev/null || true
docker run -d \
	--name keycloak \
	--network rtg-network \
	-p 8080:8080 \
	keycloak-api
```

3. Configure RestTestGen target API and host.

In `tools/resttestgen/rtg-config.yml`:

```yaml
apiUnderTest: keycloak
```

In `tools/resttestgen/apis/keycloak/api-config.yml`:

```yaml
host: "http://keycloak:8080"
```

4. Build and run RestTestGen on the same Docker network.

```bash
cd <project-root>/tools/resttestgen

docker build -t rtg .
docker run --rm \
	--network rtg-network \
	-v "$PWD/apis:/app/apis" \
	-v "$PWD/rtg-config.yml:/app/rtg-config.yml" \
	-v "$PWD/strategy-config.yml:/app/strategy-config.yml" \
	rtg
```

5. Read results in `tools/resttestgen/apis/keycloak/results`.

Optional for host-side inspection/debugging only:

- publish `-p 9090:9090` to inspect proxy traffic from the host;
- publish `-p 12345:12345` only if you need external JaCoCo TCP access;
- set `-e TOOL=rtg -e RUN=1` only to customize API container output folder naming.

For authenticated targets, choose one of the WFC-configured APIs listed above, run its API container on `rtg-network`, and set the matching `host` in the corresponding `api-config.yml` to `http://<container-name>:8080` (or `:9090` if you intentionally route RTG through the proxy).

## Notes and Current Limits

- Dataset and images are large (storage and bandwidth planning needed).
- Gravitee is a known scaling ceiling in current resource settings (timeout/OOM risk on long runs).
- Operationalized WFC categories currently cover F100, F102, F203; additional categories are modeled for future oracle extensions.
