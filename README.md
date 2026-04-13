# RESTTestGen - WFC Integration & Benchmark

---

## Overview

This project extends [RestTestGen](https://github.com/SeUniVr/RestTestGen), a black-box REST API fuzzer, with native support for the [Web Fuzzing Commons (WFC)](https://github.com/WebFuzzingCommons) standard. The work covers:

- **WFC Authentication** integration (including a novel `signupEndpoint` extension)
- **WFC Fault** categorization and end-to-end **WFC Report** integration in RestTestGen
- A curated benchmark of **17 Dockerized open-source REST APIs**

---

## Context

The REST API testing ecosystem is fragmented: tools produce incompatible outputs, fault semantics are inconsistent, and benchmark selection varies across studies. Authentication support is particularly weak — of 23 fuzzers surveyed, only 6 support dynamic authentication at runtime, and those typically rely on tool-specific scripts.

WFC Authentication (introduced September 2025 by the EvoMaster group) addresses this with a declarative, tool-agnostic format. Before this project, EvoMaster was the only fuzzer with native support. This work adds native WFC support to RestTestGen, alongside Schemathesis, which has recently announced it as well.

---

## What Was Built

### 1. Benchmark Curation
- 41 candidate APIs investigated; **17 integrated**, 24 rejected with documented reasons
- Selection criteria: Java compatibility, OpenAPI quality, Docker reproducibility, runtime stability
- Domains: IAM, BPM, API management, healthcare, finance, social, tracking, and more

### 2. Infrastructure
- Per-API Dockerization with Java runtime compatibility and startup health checks
- **JaCoCo** instrumentation for code coverage
- **mitmproxy** for full HTTP interaction capture
- Auth configs, dictionaries, and setup scripts per API

### 3. WFC Authentication (RestTestGen)
Java components implemented:
- `WfcAuthHandler` — parses `auth.yaml`, executes signup/login, extracts tokens
- `WfcAuthInfo` — tracks token state, expiry, retries, fallback mode

Supported flows:
- Basic authentication (fixed headers)
- JWT and OAuth2 ROPC login endpoint flows
- `signupEndpoint` extension for APIs requiring registration before login
- Automatic token refresh and graceful fallback to unauthenticated mode

### 4. WFC Fault Categorization

| Oracle | Condition | WFC Category |
|---|---|---|
| StatusCodeOracle | HTTP 5xx | F100 — server error |
| ErrorStatusCodeOracle | 2xx on invalid input | F102 — validation bypass |
| ErrorStatusCodeOracle | 5xx on invalid input | F100 — server error |
| MassAssignmentOracle | Protected field persisted | F203 — mass assignment |

A conservative fallback ensures uncaptured 5xx responses are always classified as F100.

### 5. WFC Report Generation
- `WfcReportWriter` generates JSON output aligned with WFC schema v0.2.0
- Integrated at end-of-session with minimal impact on existing orchestration
- Produces a single machine-readable artifact per run (`wfc-report.json`) with faults, REST problem details, and coverage extras
- Completes the pipeline from oracle verdicts to standardized report output (`oracle -> category -> WFC JSON`)

---

## Dataset

**17 containerized APIs total:**
`alfresco`, `bezkoder`, `cassandra-management-api`, `erc20`, `flightsearchapi`, `flowable-process`, `gestaohospitalar`, `gravitee`, `kafka-rest`, `keycloak`, `nexus`, `notebookmanager`, `petclinic`, `quartzmanager`, `realworld-backend-micronaut`, `spring-kafka-publisher`, `traccar`

**9 with WFC Authentication configurations:**
`alfresco`, `flightsearchapi`, `flowable-process`, `gravitee`, `keycloak`, `nexus`, `quartzmanager`, `realworld-backend-micronaut`, `traccar`

---

## Results

### Authentication impact (WFC Auth vs. no-auth)

| API | No Auth | With Auth |
|---|---|---|
| Flowable | 0 | 1410 faults |
| Keycloak | 0 | 698 faults |
| Traccar | 0 | 289 faults |
| QuartzManager | 0 | 286 faults |
| Alfresco | 65 | 296 (+355%) |
| RealWorld | 133 | 471 (+254%) |
| Nexus | 99 total (6 F100, 93 F102) | 30 total (30 F100, 0 F102) |

> Nexus shows that total fault counts alone can be misleading — category-level analysis reveals a qualitative shift toward more severe faults.

### WFC Reporting baseline (17 APIs)

- 16/17 APIs completed (Gravitee excluded: OOM)
- **33,461 faults** detected total — 70% F100, 30% F102
- Mean status-code coverage: **48.7%**

### Mutation testing (10 APIs, 5 mutants)

In this thesis, a **mutant** is a small, intentional code change in RestTestGen used to simulate a realistic regression and verify whether the testing/reporting pipeline detects it.

- A mutant is **killed** when it causes a measurable behavioral shift compared to baseline runs.
- A mutant **survives** when differences stay within noise or no observable impact appears.
- A mutant is **equivalent** when the change is not observable for a given API/context.

All mutants were executed one-at-a-time to isolate effects:

| Mutant | Changed component | Intent | Kill rate |
|---|---|---|---|
| M1 | `StatusCodeOracle` | Turn 5xx into `UNKNOWN` to stress F100 detection | 100% |
| M2 | `ErrorStatusCodeOracle` | Turn 2xx on invalid input into `PASS` to suppress F102 | 100% |
| M3 | `ErrorFuzzer` | Remove one mutator to reduce error-generation diversity | 78% |
| M4 | `Value provider` | Disable enum/example priority to degrade input semantics | 70% |
| M5 | `NominalFuzzer` | Force inclusion of all optional parameters | 100% |

This mutation campaign validates both detection sensitivity and fault-category stability under controlled regressions.

---

## Stack

| Layer | Technology |
|---|---|
| Fuzzer | RestTestGen (Java) |
| Containerization | Docker |
| Coverage | JaCoCo |
| Traffic capture | mitmproxy |
| Auth standard | WFC Authentication (auth.yaml) |
| Report standard | WFC Report schema v0.2.0 |
| API specs | OpenAPI 3.x |

---

## Quick Start

### 1. Create a Docker bridge network
```bash
docker network create rtg-network 2>/dev/null || true
```

### 2. Build and run an API (example: keycloak)
```bash
docker build -f apis/keycloak/Dockerfile -t keycloak-api .
docker rm -f keycloak 2>/dev/null || true
docker run -d --name keycloak --network rtg-network -p 8080:8080 keycloak-api
```

### 3. Configure RestTestGen

In `tools/resttestgen/rtg-config.yml`:
```yaml
apiUnderTest: keycloak
```

In `tools/resttestgen/apis/keycloak/api-config.yml`:
```yaml
host: "http://keycloak:8080"
```

### 4. Build and run RestTestGen
```bash
cd tools/resttestgen

docker build -t rtg .
docker run --rm \
  --network rtg-network \
  -v "$PWD/apis:/app/apis" \
  -v "$PWD/rtg-config.yml:/app/rtg-config.yml" \
  -v "$PWD/strategy-config.yml:/app/strategy-config.yml" \
  rtg
```

### 5. Read results
```
tools/resttestgen/apis/keycloak/results/
```

For authenticated targets, choose one of the 9 WFC-configured APIs and set `host: "http://<container-name>:8080"` in its `api-config.yml`.

--- 

## Authors

Simone Xiao, Edoardo Bazzotti

