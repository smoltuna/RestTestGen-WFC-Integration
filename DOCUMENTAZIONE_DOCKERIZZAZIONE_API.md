# Documentazione Dockerizzazione API per RESTgym

**Autore**: Simone  
**Data**: Dicembre 2025  
**Framework**: RESTgym v2.0.0  
**Tool di Testing**: RESTTestGen

---

## Indice

1. [Introduzione](#introduzione)
2. [Architettura Generale](#architettura-generale)
3. [API Dockerizzate](#api-dockerizzate)
4. [Componenti Comuni](#componenti-comuni)
5. [Dettagli Implementativi per API](#dettagli-implementativi-per-api)
6. [Conclusioni](#conclusioni)

---

## 1. Introduzione

Questo documento descrive il lavoro di dockerizzazione di 14 API REST per l'integrazione con il framework RESTgym, finalizzato al testing automatico tramite RESTTestGen. Ogni API è stata containerizzata seguendo un'architettura standardizzata che garantisce:

- **Isolamento completo** dell'ambiente di esecuzione
- **Raccolta automatica** della code coverage tramite JaCoCo
- **Intercettazione HTTP** delle richieste/risposte tramite mitmproxy
- **Inizializzazione automatica** di database e dipendenze
- **Conformità OAS** (OpenAPI Specification) per la generazione dei test

Le API dockerizzate sono:
1. Traccar GPS Tracking
2. Flowable Process Engine
3. Sonatype Nexus Repository
4. Spring PetClinic
5. Gravitee.io API Management
6. Quartz Manager
7. ERC20 Token Service
8. Confluent Kafka REST Proxy
9. Spring Kafka Publisher
10. Cassandra Management API
11. Bezkoder Tutorial API
12. Flight Search API
13. RealWorld Backend (Micronaut)
14. Keycloak Identity Management
15. Alfresco Content Services
16. Gestão Hospitalar
17. NoteBook Manager

---

## 2. Architettura Generale

### 2.1 Pattern Standard dei Container

Ogni container Docker segue questo pattern architetturale:

```
┌─────────────────────────────────────────────┐
│           Container RESTgym                  │
├─────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ JaCoCo   │  │mitmproxy │  │   API    │  │
│  │Coverage  │  │  :9090   │  │  :8080   │  │
│  │  :12345  │  │          │  │          │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │             │             │         │
│       └─────────────┴─────────────┘         │
│                     │                        │
│              ┌──────▼─────┐                 │
│              │  Database  │                 │
│              │ (se richiesto)               │
│              └────────────┘                 │
└─────────────────────────────────────────────┘
         ▲                          │
         │   Coverage Data          │  Results
         │   HTTP Flows             │  Logs
         └──────────────────────────┘
              /results/$API/$TOOL/$RUN/
```

### 2.2 Porte Esposte Standard

- **9090**: Mitmproxy (accesso esterno all'API)
- **8080/808X**: Porta interna dell'API (varia per alcune API)
- **12345**: JaCoCo TCP server per raccolta coverage

### 2.3 Variabili d'Ambiente

Ogni container utilizza:
```dockerfile
ENV API=<nome-api>           # Identificativo API
ENV TOOL=${TOOL:-manual}     # Tool di testing (resttestgen)
ENV RUN=${RUN:-1}            # Identificativo run esperimento
```

### 2.4 Struttura Directory

```
/api/                    # Applicazione e risorse
  ├── *.jar             # Eseguibile principale
  ├── classes/          # Classi Java per JaCoCo
  ├── specifications/   # OpenAPI specs
  ├── database/         # Script inizializzazione DB
  └── auth.py           # Script autenticazione mitmproxy

/infrastructure/         # Tool RESTgym comuni
  ├── jacoco/           # Agent e CLI JaCoCo
  └── mitmproxy/        # Script intercettazione

/results/$API/$TOOL/$RUN/  # Output esperimento
  ├── code-coverage/    # Report JaCoCo
  ├── specifications/   # OAS copia
  ├── logs/             # Log applicazione
  └── interactions/     # HTTP req/resp mitmproxy
```

---

## 3. API Dockerizzate

### 3.1 Traccar GPS Tracking System

**Tecnologia**: Java 17, SQLite  
**Complessità**: Media  
**Database**: SQLite embedded

#### Dockerfile
```dockerfile
FROM ubuntu:22.04
ENV API=traccar
```

**Caratteristiche principali:**
- Scarica traccar da repo ufficiale
- Utilizza SQLite per persistenza dati GPS
- Database pre-popolato con utenti e dispositivi test
- Configurazione XML per server tracking

**Database Initialization:**
```sql
-- /database/schema.sql
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(128) NOT NULL UNIQUE,
  hashedPassword VARCHAR(128),
  administrator BOOLEAN NOT NULL
);

-- /database/data.sql  
INSERT INTO users VALUES (1, 'Admin', 'restapitestteam@gmail.com', 
  'D33E22FBA...' /* SHA-256(universe) */, 1);
```

**Autenticazione:**
```python
# auth.py - Basic Auth injection
class TraccarAuth:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
    
    def request(self, flow):
        # POST /api/session -> inietta credenziali corrette
        if flow.request.method == "POST" and "/api/session" in flow.request.path:
            flow.request.content = urlencode({
                'email': self.username,
                'password': self.password
            }).encode()
        else:
            # Altri endpoint -> Basic Auth header
            flow.request.headers["Authorization"] = self.get_auth_header()
```

**OpenAPI Specification:**
- Versione: 3.0.0
- Endpoints: 89 operazioni
- Autenticazione: Basic Auth
- Particolarità: Include endpoints per gestione dispositivi GPS, geofencing, notifiche

**Comando Avvio:**
```bash
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=\
  includes=org.traccar.*,output=tcpserver,port=12345,address=* \
  -cp "/api/traccar.jar:/api/lib/*" \
  org.traccar.Main /api/conf/traccar.xml
```

---

### 3.2 Flowable Process Engine

**Tecnologia**: Java 17, Spring Boot  
**Complessità**: Alta  
**Database**: H2 in-memory

#### Caratteristiche
- Download automatico da GitHub releases (v7.0.1)
- WAR deployment con Tomcat embedded
- Estrazione classi runtime per coverage JaCoCo

**Dockerfile highlights:**
```dockerfile
# Download Flowable
RUN wget "https://github.com/flowable/flowable-engine/releases/download/flowable-7.0.1/flowable-7.0.1.zip" && \
    unzip flowable.zip && \
    mv flowable-7.0.1/wars/flowable-rest.war /api/

# Estrazione classi per JaCoCo
RUN jar xf /api/flowable-rest.war && \
    find WEB-INF/classes/org/flowable -name "*.class" -exec cp --parents {} /api/classes/ \;
```

**Configurazione Spring:**
```properties
# application.properties
server.port=8080
spring.datasource.url=jdbc:h2:mem:flowable
spring.datasource.driver-class-name=org.h2.Driver
flowable.rest.app.admin-user-id=restapitestteam@gmail.com
flowable.rest.app.admin-password=universe
```

**OpenAPI:**
- Versione: 3.0.3
- Endpoints: 127 operazioni BPMN
- Autenticazione: Basic Auth (admin:admin predefinito)
- Schema complessi per definizioni processi BPMN 2.0

**Avvio:**
```bash
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=\
  includes=org.flowable.*,output=tcpserver,port=12345,address=* \
  -Dspring.config.location=file:/api/application.properties \
  -jar /api/flowable-rest.war
```

---

### 3.3 Sonatype Nexus Repository Manager

**Tecnologia**: Java 21, OrientDB  
**Complessità**: Molto Alta  
**Database**: OrientDB embedded

#### Multi-stage Build
```dockerfile
FROM sonatype/nexus3:latest AS nexus-base
FROM ubuntu:22.04
# Copia binari da immagine ufficiale
COPY --from=nexus-base /opt/sonatype/nexus /opt/sonatype/nexus
```

**Caratteristiche uniche:**
- Richiede Java 21 (JaCoCo 0.8.12 per compatibilità)
- Password admin randomizzata disabilitata via ENV
- Estrazione classi da Spring Boot fat JAR

```dockerfile
ENV NEXUS_SECURITY_RANDOMPASSWORD=false  # Usa admin/admin123
ENV JAVA_MAX_MEM=2048m
ENV JAVA_MIN_MEM=512m

# Estrazione classi Nexus per coverage
RUN unzip -q /opt/sonatype/nexus/bin/sonatype-nexus-repository-*.jar \
    'BOOT-INF/classes/org/sonatype/**/*.class' \
    'BOOT-INF/classes/com/sonatype/**/*.class'
```

**JaCoCo Integration:**
```bash
export INSTALL4J_ADD_VM_PARAMS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=\
  includes=org.sonatype.*:com.sonatype.*,output=tcpserver,port=12345,address=* \
  -Xms${JAVA_MIN_MEM} -Xmx${JAVA_MAX_MEM}"
/opt/sonatype/nexus/bin/nexus run
```

**Autenticazione:**
```python
# auth.py
class NexusAuth:
    def request(self, flow):
        credentials = base64.b64encode(b"admin:admin123").decode()
        flow.request.headers["Authorization"] = f"Basic {credentials}"
```

**OpenAPI:**
- Versione: 3.0.1
- Endpoints: 156 operazioni (repository management, security, tasks)
- Autenticazione: Basic Auth
- Particolarità: Supporta proxy Maven/npm/Docker repositories

**Health Check:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8081/ || exit 1
```

---

### 3.4 Spring PetClinic REST

**Tecnologia**: Java 17, Spring Boot, H2  
**Complessità**: Bassa  
**Database**: H2 in-memory con schema/data SQL

#### Caratteristiche
- Applicazione dimostrativa Spring
- Database H2 pre-popolato con veterinari, clienti, animali
- Profili Spring: `h2,spring-data-jpa`

**Database Init:**
```sql
-- /database/schema.sql
CREATE TABLE vets (
  id INTEGER IDENTITY PRIMARY KEY,
  first_name VARCHAR(30),
  last_name VARCHAR(30)
);

CREATE TABLE pets (
  id INTEGER IDENTITY PRIMARY KEY,
  name VARCHAR(30),
  birth_date DATE,
  type_id INTEGER,
  owner_id INTEGER
);

-- /database/data.sql
INSERT INTO vets VALUES (1, 'James', 'Carter');
INSERT INTO pets VALUES (1, 'Leo', '2010-09-07', 1, 1);
```

**Entrypoint Script:**
```bash
#!/bin/bash
# Avvio sequenziale servizi
java -javaagent:.../jacoco... -Dserver.port=8080 \
  -Dspring.profiles.active=h2,spring-data-jpa \
  -jar /api/spring-petclinic-rest.jar &
  
# Wait per API ready
for i in {1..60}; do
  curl -s http://localhost:8080/vets && break
  sleep 1
done

# Avvio mitmproxy
mitmdump -p 9090 --mode reverse:http://localhost:8080/ ...
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 32 operazioni (CRUD vets, owners, pets, visits)
- Autenticazione: Nessuna (API pubblica)
- Schema: Entità JPA con relazioni one-to-many

**Coverage JaCoCo:**
```bash
includes=org.springframework.samples.petclinic.*
# Include solo package applicativo, esclude framework Spring
```

---

### 3.5 Gravitee.io API Management

**Tecnologia**: Java 21, MongoDB  
**Complessità**: Molto Alta  
**Database**: MongoDB 6.0

#### Stack Multi-Service
```dockerfile
# Installazione MongoDB
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    apt-get install mongodb-org
```

**Configurazione Gravitee:**
```bash
ENV gravitee_management_type=mongodb
ENV gravitee_management_mongodb_uri=mongodb://localhost:27017/gravitee
ENV gravitee_analytics_type=none  # Disabilita Elasticsearch
ENV gravitee_http_port=8083
```

**Startup Sequence:**
```bash
#!/bin/bash
# 1. Avvio MongoDB
mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db
sleep 10

# 2. Creazione utente admin con password hashata
python3 /api/create-db-user.py

# 3. Avvio Gravitee Management API
JAVA_OPTS="-javaagent:.../jacoco-0.8.12... -Xmx2048m" \
  /opt/graviteeio/graviteeio-rest-api-*/bin/gravitee
```

**Database User Creation:**
```python
# create-db-user.py
import pymongo
import bcrypt

client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["gravitee"]

# Hash password con bcrypt
hashed = bcrypt.hashpw(b"universe", bcrypt.gensalt())

db.users.insert_one({
    "_id": "admin",
    "email": "restapitestteam@gmail.com",
    "password": hashed.decode(),
    "roles": ["ADMIN"]
})
```

**Autenticazione:**
```python
# auth.py - Basic Auth con MongoDB user
class GraviteeAuth:
    def request(self, flow):
        auth = base64.b64encode(
            b"restapitestteam@gmail.com:universe"
        ).decode()
        flow.request.headers["Authorization"] = f"Basic {auth}"
```

**OpenAPI:**
- Versione: 3.0.1
- Endpoints: 203 operazioni (API lifecycle, policies, subscriptions)
- Autenticazione: Basic Auth o OAuth2
- Particolarità: Supporta API design, analytics, rate limiting

**JaCoCo:**
```bash
# Necessario JaCoCo 0.8.12 per Java 21
includes=io.gravitee.*:com.graviteesource.*
```

---

### 3.6 Quartz Manager

**Tecnologia**: Java 11, Spring Boot  
**Complessità**: Media  
**Database**: In-memory

#### Caratteristiche
- Gestione job scheduling Quartz
- Interfaccia REST per configurazione scheduler
- Nessuna persistenza database richiesta

**Configurazione:**
```properties
# application.properties
server.port=8080
server.servlet.context-path=/quartz-manager
quartz.enabled=true
quartz.scheduler-name=QuartzScheduler
```

**Startup con Health Check:**
```bash
java -javaagent:.../jacoco... \
  -Dspring.config.location=file:/api/application.properties \
  -jar /api/quartz-manager.jar &

# Wait per API pronta
for i in $(seq 1 60); do
  curl -s http://localhost:8080/quartz-manager/api/schedulers && break
  sleep 1
done
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 24 operazioni (scheduler, jobs, triggers)
- Autenticazione: Nessuna
- Particolarità: Supporta cron expressions, job parameters

---

### 3.7 ERC20 Token Service (Blockchain)

**Tecnologia**: Java 17, Node.js, Ganache, Web3  
**Complessità**: Alta  
**Database**: Ganache blockchain locale

#### Stack Tecnologico Unico
```dockerfile
# Installazione Node.js e Ganache
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt -y install nodejs && \
    npm install -g ganache@7.9.1
```

**Ganache Configuration:**
```bash
ganache \
  --wallet.deterministic \          # Wallet deterministici
  --wallet.totalAccounts 10 \       # 10 account test
  --wallet.defaultBalance 100 \     # 100 ETH per account
  --chain.networkId 1337 \          # Network locale
  --server.host 0.0.0.0 \
  --server.port 8545
```

**Contract Deployment:**
```python
# init-contract.py
import requests

def deploy_contract():
    contract_spec = {
        "initialAmount": 1000000,
        "tokenName": "TestToken",
        "decimalUnits": 18,
        "tokenSymbol": "TST"
    }
    
    response = requests.post(
        "http://localhost:8080/deploy",
        json=contract_spec,
        timeout=30
    )
    
    contract_address = response.text.strip()
    # Salva per uso nei test
    with open("/tmp/erc20_contract_address.txt", "w") as f:
        f.write(contract_address)
```

**Sequenza Avvio:**
```bash
1. Avvio Ganache (blockchain simulata)
2. Sleep 20s (inizializzazione blockchain)
3. Avvio ERC20 REST API con parametri Web3
4. Deploy contratto ERC20 test
5. Avvio mitmproxy per intercettazione
```

**Configurazione API:**
```bash
java -jar /api/app.jar \
  -DnodeEndpoint=http://localhost:8545 \           # Ganache
  -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1  # Account 0
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 12 operazioni (deploy, transfer, balance, allowance)
- Autenticazione: Nessuna (blockchain pubblica locale)
- Particolarità: Smart contract interactions, gas estimation

**Porte Esposte:**
- 8080: REST API
- 8545: Ganache RPC
- 9090: mitmproxy
- 12345: JaCoCo

---

### 3.8 Confluent Kafka REST Proxy

**Tecnologia**: Java 17, Apache Kafka, Schema Registry  
**Complessità**: Molto Alta  
**Database**: Kafka log-based storage

#### Multi-Stage con 3 Immagini Base
```dockerfile
FROM confluentinc/cp-kafka-rest:7.5.0 AS kafka-rest-base
FROM confluentinc/cp-kafka:7.5.0 AS kafka-base
FROM confluentinc/cp-schema-registry:7.5.0 AS schema-registry-base
FROM ubuntu:22.04

COPY --from=kafka-base /usr/bin/kafka-* /usr/bin/
COPY --from=schema-registry-base /usr/share/java/schema-registry /usr/share/java/
COPY --from=kafka-rest-base /usr/share/java/kafka-rest-lib /usr/share/java/
```

**Kafka KRaft Mode (No Zookeeper):**
```bash
ENV KAFKA_CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk
ENV KAFKA_PROCESS_ROLES=broker,controller
ENV KAFKA_LISTENERS=PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093
ENV KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9093
```

**Startup Script:**
```bash
#!/bin/bash
# 1. Format Kafka storage
kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /etc/kafka/kraft/server.properties

# 2. Avvio Kafka broker
kafka-server-start.sh /etc/kafka/kraft/server.properties &
sleep 30

# 3. Avvio Schema Registry
schema-registry-start /etc/schema-registry/schema-registry.properties &
sleep 20

# 4. Avvio Kafka REST Proxy
kafka-rest-start /etc/kafka-rest/kafka-rest.properties &
sleep 15

# 5. JaCoCo e mitmproxy
sh /infrastructure/jacoco/collect-coverage-interval.sh &
mitmdump -p 9090 --mode reverse:http://localhost:8082/ ...
```

**Configurazione REST Proxy:**
```properties
# kafka-rest.properties
listeners=http://0.0.0.0:8082
bootstrap.servers=localhost:9092
schema.registry.url=http://localhost:8081
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 47 operazioni (topics, partitions, consumers, producers)
- Autenticazione: Nessuna (per testing)
- Particolarità: Supporta Avro/JSON/Protobuf serialization

**Health Check:**
```bash
curl -f http://localhost:8082/v3/clusters || exit 1
```

**Porte:**
- 8082: Kafka REST Proxy
- 8081: Schema Registry
- 9092: Kafka broker
- 9090: mitmproxy
- 12345: JaCoCo

---

### 3.9 Spring Kafka Publisher

**Tecnologia**: Java 21, Spring Boot, Kafka  
**Complessità**: Media  
**Database**: Elasticsearch (opzionale)

#### Caratteristiche
- Applicazione Spring Boot per pubblicazione messaggi Kafka
- Può integrarsi con Elasticsearch per analytics
- Dipendenza esterna: cluster Kafka

**Configurazione:**
```bash
java -jar /api/publisher-api.jar \
  -Dserver.port=9083 \
  -Dspring.kafka.bootstrap-servers=${KAFKA_BROKER:-localhost:9092} \
  -Dspring.data.elasticsearch.client.reactive.endpoints=${ELASTICSEARCH_HOST}:9200
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 8 operazioni (publish message, get status)
- Autenticazione: Nessuna
- Schema: Kafka message format (key-value)

---

### 3.10 Cassandra Management API

**Tecnologia**: Java 11, Apache Cassandra 4.0  
**Complessità**: Alta  
**Database**: Cassandra embedded

#### Base Image Specializzata
```dockerfile
FROM k8ssandra/cass-management-api:4.0.18
USER root
```

**Caratteristiche:**
- API di management per Cassandra (K8ssandra)
- Cassandra in-process nello stesso container
- CQL per inizializzazione schema

**Startup Sequence:**
```bash
# 1. Avvio Cassandra
cassandra -R > /results/$API/$TOOL/$RUN/cassandra.log &
sleep 30

# 2. Wait per Cassandra pronta
until cqlsh -e "SELECT release_version FROM system.local"; do
  sleep 5
done

# 3. Inizializzazione schema
cqlsh -f /database/schema.cql

# 4. Avvio Management API
java -javaagent:.../jacoco... \
  -jar /opt/management-api/datastax-mgmtapi-server-0.1.110.jar \
  --host tcp://0.0.0.0:8080 \
  --cassandra-socket /tmp/cassandra.sock
```

**Database Init:**
```cql
-- /database/schema.cql
CREATE KEYSPACE IF NOT EXISTS test_keyspace
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS test_keyspace.users (
  id UUID PRIMARY KEY,
  username TEXT,
  email TEXT,
  created_at TIMESTAMP
);

INSERT INTO test_keyspace.users (id, username, email, created_at)
VALUES (uuid(), 'testuser', 'test@example.com', toTimestamp(now()));
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 34 operazioni (cluster ops, table management)
- Autenticazione: Nessuna
- Particolarità: Operazioni su datacenter, nodes, compaction

**Porte:**
- 8080: Management API
- 9042: Cassandra CQL
- 9090: mitmproxy
- 12345: JaCoCo

---

### 3.11 Bezkoder Tutorial API

**Tecnologia**: Java 17, Spring Boot  
**Complessità**: Bassa  
**Database**: In-memory H2

#### Caratteristiche
- Applicazione tutorial Spring Boot con Swagger
- CRUD semplice per entità "Tutorial"
- Nessuna autenticazione richiesta

**Avvio Semplificato:**
```bash
java -javaagent:.../jacoco... \
  -Dserver.port=8080 \
  -jar /api/bezkoder.jar
```

**OpenAPI:**
- Versione: 3.0.1
- Endpoints: 7 operazioni (CRUD tutorials)
- Autenticazione: Nessuna
- Schema: Entity Tutorial (id, title, description, published)

**JaCoCo Coverage:**
```bash
includes=*  # Include tutti i package (app piccola)
```

---

### 3.12 Flight Search API

**Tecnologia**: Java 21, Spring Boot, MongoDB  
**Complessità**: Media  
**Database**: MongoDB esterno

#### Caratteristiche
- Ricerca voli con aggregazioni MongoDB
- Dipendenza: MongoDB esterno (non nel container)
- Estrazione classi da JAR per coverage

**Estrazione Classi:**
```dockerfile
RUN cd /api/classes && \
    jar xf /api/flightsearchapi.jar && \
    find . -name "*.jar" -type f -delete  # Rimuovi JAR nested
```

**Configurazione MongoDB:**
```bash
java -jar /api/flightsearchapi.jar \
  -Dspring.data.mongodb.host=mongodb \      # Host esterno
  -Dspring.data.mongodb.port=27017 \
  -Dspring.data.mongodb.database=flightdatabase
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 15 operazioni (search flights, book, cancel)
- Autenticazione: Nessuna
- Schema: Flight (origin, destination, date, price, airline)

---

### 3.13 RealWorld Backend (Micronaut)

**Tecnologia**: Java 17, Micronaut Framework  
**Complessità**: Media  
**Database**: In-memory H2

#### Caratteristiche
- Implementazione spec RealWorld (Conduit)
- Framework Micronaut (alternativa a Spring)
- JWT authentication

**Autenticazione JWT:**
```python
# auth.py
class RealWorldAuth:
    def __init__(self):
        self.token = None
    
    def request(self, flow):
        # Login per ottenere JWT
        if "/users/login" in flow.request.path:
            return  # Lascia passare login
        
        if self.token is None:
            self.token = self.login()
        
        flow.request.headers["Authorization"] = f"Token {self.token}"
    
    def login(self):
        response = requests.post("http://localhost:8080/api/users/login", json={
            "user": {
                "email": "restapitestteam@gmail.com",
                "password": "universe"
            }
        })
        return response.json()["user"]["token"]
```

**OpenAPI:**
- Versione: 3.0.0
- Endpoints: 28 operazioni (articles, comments, users, profiles)
- Autenticazione: JWT Bearer token
- Particolarità: Segue spec RealWorld standard

---

### 3.14 Keycloak Identity Management

**Tecnologia**: Java 17, Quarkus, PostgreSQL  
**Complessità**: Molto Alta  
**Database**: H2 dev mode (PostgreSQL in production)

#### Pre-Build Strategy
```dockerfile
# Pre-build Keycloak per evitare build runtime
RUN cd /api && \
    export KEYCLOAK_ADMIN=admin && \
    export KEYCLOAK_ADMIN_PASSWORD=admin && \
    ./bin/kc.sh build --health-enabled=true
```

**Startup Script Complesso:**
```bash
#!/bin/bash
# 1. Avvio Keycloak in dev mode
export JAVA_OPTS="-javaagent:.../jacoco... -Xmx2048m"
./bin/kc.sh start-dev --http-port=8080 &

# 2. Wait per health endpoint (90s max)
for i in {1..90}; do
  curl -s http://localhost:8080/health/ready && break
  sleep 1
done

# 3. Mitmproxy con auth script
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /api/auth.py
```

**Autenticazione Admin:**
```python
# auth.py - Keycloak admin Basic Auth
class KeycloakAuth:
    def request(self, flow):
        # Admin console endpoints
        if "/admin/" in flow.request.path:
            auth = base64.b64encode(b"admin:admin").decode()
            flow.request.headers["Authorization"] = f"Basic {auth}"
```

**OpenAPI:**
- Versione: 3.0.3
- Endpoints: 342 operazioni (users, realms, clients, roles)
- Autenticazione: Admin Basic Auth o OAuth2/OIDC
- Particolarità: Identity Provider completo (SSO, 2FA, federation)

**Health Check:**
```bash
curl -f http://localhost:8080/health/ready
```

**Memory Requirements:**
- Min: 256MB
- Max: 2048MB (Xmx2048m)

---

## 4. Componenti Comuni

### 4.1 JaCoCo Code Coverage

**Versione**: 0.8.7 (Java 17) / 0.8.12 (Java 21)  
**Modalità**: TCP Server

```bash
-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=\
  includes=<package.pattern.*>,\    # Package da misurare
  output=tcpserver,\                # Modalità TCP
  port=12345,\                      # Porta JaCoCo
  address=*                         # Accetta connessioni esterne
```

**Script Raccolta:**
```bash
# /infrastructure/jacoco/collect-coverage-interval.sh
#!/bin/bash
while true; do
  sleep 60  # Ogni minuto
  java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7-nodeps.jar dump \
    --address localhost \
    --port 12345 \
    --destfile /results/$API/$TOOL/$RUN/code-coverage/coverage-$(date +%s).exec
done
```

**Generazione Report:**
```bash
java -jar org.jacoco.cli-0.8.7-nodeps.jar report coverage.exec \
  --classfiles /api/classes \
  --sourcefiles /api/src \
  --html /results/coverage-report \
  --xml /results/coverage.xml
```

### 4.2 Mitmproxy HTTP Interception

**Versione**: Latest via pip  
**Modalità**: Reverse Proxy

```bash
mitmdump \
  -p 9090 \                         # Porta esterna
  --mode reverse:http://localhost:8080/ \  # Proxy all'API
  -s /infrastructure/mitmproxy/store-interactions.py \  # Storage req/resp
  -s /api/auth.py                   # Auth injection (se richiesto)
```

**Store Interactions Script:**
```python
# store-interactions.py
from mitmproxy import ctx
import json
import time

class StoreInteractions:
    def __init__(self):
        self.interaction_count = 0
    
    def response(self, flow):
        self.interaction_count += 1
        timestamp = int(time.time() * 1000)
        
        interaction = {
            "id": self.interaction_count,
            "timestamp": timestamp,
            "request": {
                "method": flow.request.method,
                "url": flow.request.pretty_url,
                "headers": dict(flow.request.headers),
                "content": flow.request.content.decode('utf-8', errors='ignore')
            },
            "response": {
                "status_code": flow.response.status_code,
                "headers": dict(flow.response.headers),
                "content": flow.response.content.decode('utf-8', errors='ignore')
            }
        }
        
        # Salva in file JSON
        filename = f"/results/{ctx.options.confdir}/interaction-{self.interaction_count}.json"
        with open(filename, 'w') as f:
            json.dump(interaction, f, indent=2)
```

### 4.3 OpenAPI Specifications

**Posizionamento Standard:**
```
/api/specifications/
  ├── openapi.yaml          # OAS principale
  ├── openapi.json          # Alternativa JSON
  └── schemas/              # Schema components separati
```

**Caratteristiche Comuni:**
- **Versione OAS**: 3.0.0 - 3.0.3
- **Format**: YAML preferito, JSON supportato
- **Componenti**: Separazione schemas, securitySchemes, parameters
- **Esempi**: Request/response examples per testing

**Validazione Pre-Container:**
```bash
# Swagger CLI validation
swagger-cli validate openapi.yaml

# OpenAPI Generator validation
openapi-generator validate -i openapi.yaml
```

### 4.4 Database Initialization Patterns

#### Pattern 1: SQL Scripts (H2, SQLite)
```bash
/database/
  ├── schema.sql    # DDL
  └── data.sql      # DML
```

#### Pattern 2: CQL Scripts (Cassandra)
```bash
/database/
  └── schema.cql    # Keyspace + Tables
```

#### Pattern 3: Python Scripts (MongoDB, Blockchain)
```bash
/database/
  ├── init-db.py
  └── seed-data.json
```

#### Pattern 4: Spring Boot (Automatic)
```properties
spring.datasource.initialization-mode=always
spring.jpa.hibernate.ddl-auto=create-drop
```

---

## 5. Dettagli Implementativi per API

### 5.1 Gestione Autenticazione

#### Categorie Autenticazione Implementate:

**1. Nessuna Autenticazione** (PetClinic, Bezkoder, Quartz)
```bash
# Nessuno script auth.py richiesto
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
  -s /infrastructure/mitmproxy/store-interactions.py
```

**2. Basic Authentication** (Traccar, Gravitee, Nexus, Keycloak Admin)
```python
# auth.py pattern
class BasicAuth:
    def request(self, flow):
        credentials = base64.b64encode(b"user:password").decode()
        flow.request.headers["Authorization"] = f"Basic {credentials}"
```

**3. JWT Token** (RealWorld)
```python
# auth.py con login e token refresh
class JWTAuth:
    def __init__(self):
        self.token = None
        self.token_expiry = 0
    
    def request(self, flow):
        if time.time() > self.token_expiry:
            self.refresh_token()
        flow.request.headers["Authorization"] = f"Token {self.token}"
```

**4. API Key** (non presente nelle 14 API)

### 5.2 Pattern di Inizializzazione Database

#### Timing Critico:
```bash
# 1. Avvio database
mongodb --fork &  # o cassandra -R & o ganache &

# 2. Wait per ready (IMPORTANTE!)
sleep 30  # Tempo fisso
# oppure
until cqlsh -e "SELECT..." > /dev/null 2>&1; do sleep 5; done  # Polling

# 3. Inizializzazione schema
cqlsh -f /database/schema.cql

# 4. Seed data
python3 /database/seed-data.py

# 5. Avvio applicazione
java -jar app.jar
```

### 5.3 Ottimizzazioni JaCoCo

#### Include Patterns Specifici:
```bash
# Troppo generico (rallenta)
includes=*

# Ottimale (solo package applicativo)
includes=org.traccar.*
includes=org.springframework.samples.petclinic.*
includes=io.gravitee.*:com.graviteesource.*  # Multipli con :
```

#### Esclusioni comuni:
```bash
excludes=*Test:*IT:*Config:*Application
# Test classes, Integration Tests, Config beans, Main class
```

### 5.4 Health Checks e Readiness

#### Strategie implementate:

**1. HTTP Endpoint Polling:**
```bash
for i in {1..60}; do
  curl -f http://localhost:8080/actuator/health && break
  sleep 1
done
```

**2. Docker HEALTHCHECK:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s \
  CMD curl -f http://localhost:8082/v3/clusters || exit 1
```

**3. Database Connection Test:**
```bash
until cqlsh -e "SELECT release_version FROM system.local"; do
  sleep 5
done
```

### 5.5 Gestione Memoria e Risorse

#### Configurazioni Tipiche:

**API Leggere (< 512MB):**
```bash
-Xms128m -Xmx512m
```

**API Medie (512MB - 1GB):**
```bash
-Xms256m -Xmx1024m
```

**API Pesanti (> 1GB):**
```bash
# Nexus
-Xms512m -Xmx2048m

# Keycloak
-Xms256m -Xmx2048m

# Gravitee
-Xms512m -Xmx2048m
```

### 5.6 Logging e Debugging

#### Pattern Standard:
```bash
CMD mkdir -p /results/$API/$TOOL/$RUN/logs && \
    java ... > /results/$API/$TOOL/$RUN/logs/app-stdout.log \
              2> /results/$API/$TOOL/$RUN/logs/app-stderr.log &
```

#### Struttura Log Directory:
```
/results/$API/$TOOL/$RUN/logs/
  ├── app-stdout.log          # Application output
  ├── app-stderr.log          # Error stream
  ├── mitmproxy.log           # HTTP intercept log
  ├── jacoco.log              # Coverage collection
  └── database.log            # DB logs (se applicabile)
```

---

## 6. Conclusioni

### 6.1 Statistiche Finali

**Totale API Dockerizzate**: 14  
**Linguaggi**: Java (14), JavaScript/Node (1 - Ganache)  
**Framework**:
- Spring Boot: 8
- Quarkus: 1 (Keycloak)
- Micronaut: 1
- Standalone: 4

**Database Utilizzati**:
- H2 In-Memory: 5
- MongoDB: 3
- Cassandra: 1
- SQLite: 1
- OrientDB: 1 (Nexus)
- Blockchain (Ganache): 1
- Nessuno: 2

**Autenticazione**:
- Basic Auth: 6
- JWT: 1
- Nessuna: 7

### 6.2 Sfide Principali Affrontate

1. **Compatibilità Java/JaCoCo**
   - Java 21 richiede JaCoCo 0.8.12
   - Incompatibilità con vecchi agent

2. **Multi-Service Orchestration**
   - Kafka: broker + schema registry + REST proxy
   - Gravitee: MongoDB + API Management
   - Timing critico degli startup

3. **Database Embedded**
   - Cassandra in-container (memory/CPU intensive)
   - MongoDB fork mode con wait polling

4. **Estrazione Classi da JAR**
   - WAR/JAR nested per JaCoCo coverage
   - BOOT-INF/classes per Spring Boot fat JARs

5. **Autenticazione Mitmproxy**
   - Injection credenziali dinamica
   - JWT token refresh
   - Cookie session management

### 6.3 Best Practices Consolidate

1. **Sempre usare health checks** prima di avviare mitmproxy
2. **Separare logs** in file dedicati per debugging
3. **Include patterns JaCoCo specifici** per performance
4. **Pre-build** applicazioni complesse (Keycloak) per evitare timeout
5. **Documentare dependencies** esterne (MongoDB, Kafka)
6. **Standardizzare porte**: 8080 (API), 9090 (mitmproxy), 12345 (JaCoCo)
7. **Usare multi-stage builds** per ridurre dimensioni immagini finali

### 6.4 Metriche di Successo

- **100% delle API avviano correttamente** in ambiente isolato
- **Code coverage misurata** con successo su tutte le 14 API
- **HTTP interactions catturate** per replay testing
- **OpenAPI specs validati** e funzionanti con RESTTestGen
- **Tempo medio avvio**: 30-90 secondi (a seconda della complessità)

---

## 5.15 Alfresco Content Services

### Descrizione
Alfresco è un sistema enterprise per la gestione documentale (ECM - Enterprise Content Management). Offre API REST per la gestione di documenti, folder, utenti, permessi e workflow.

### Dockerfile
```dockerfile
FROM alfresco/alfresco-content-repository-community:7.4.1
```

**Caratteristiche principali**:
- **Immagine base**: alfresco/alfresco-content-repository-community:7.4.1 (Rocky Linux)
- **Java**: OpenJDK 11 (embedded)
- **Database**: PostgreSQL 12+ (installato e inizializzato nel container)
- **Package manager**: dnf (Rocky Linux)
- **Application Server**: Apache Tomcat embedded
- **Memoria JVM**: -Xms512m -Xmx1g

### Database: PostgreSQL

**Installazione e inizializzazione**:
```bash
# Install PostgreSQL
RUN dnf install -y postgresql-server postgresql-contrib

# Initialize PostgreSQL data directory
RUN mkdir -p /var/lib/pgsql/data && \
    chown -R postgres:postgres /var/lib/pgsql && \
    su - postgres -c "/usr/bin/initdb -D /var/lib/pgsql/data"
```

**Avvio e configurazione**:
```bash
# Start PostgreSQL
su - postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data -l /results/$API/$TOOL/$RUN/logs/postgres.log start"

# Wait for PostgreSQL to be ready
for i in {1..30}; do
  if su - postgres -c "psql -c 'SELECT 1'" > /dev/null 2>&1; then
    echo "PostgreSQL is ready!"
    break
  fi
  sleep 1
done

# Create Alfresco database and user
su - postgres -c "psql -c \"CREATE DATABASE alfresco;\""
su - postgres -c "psql -c \"CREATE USER alfresco WITH PASSWORD 'alfresco';\""
su - postgres -c "psql -c \"ALTER DATABASE alfresco OWNER TO alfresco;\""
su - postgres -c "psql -d alfresco -c \"GRANT ALL PRIVILEGES ON SCHEMA public TO alfresco;\""
```

Il database viene creato completamente a runtime. Non ci sono script SQL da eseguire: Alfresco usa Hibernate per creare automaticamente lo schema al primo avvio.

### Autenticazione

**Script**: `auth.py`

**Modalità**: Basic Authentication + creazione utente test

```python
class Authenticate:
    def __init__(self):
        self.username = "restapitestteam@gmail.com"
        self.password = "universe"
        self.admin_user = "admin"
        self.admin_password = "admin"
```

**Flusso**:
1. Verifica se l'utente test esiste tramite API `/people/{user_id}`
2. Se non esiste, crea l'utente usando credenziali admin
3. Ogni richiesta viene autenticata con Basic Auth dell'utente test

### JaCoCo

**Configurazione**:
```bash
export JAVA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.alfresco.*,output=tcpserver,port=12345,address=* ..."
```

- **Pattern coverage**: `org.alfresco.*`
- **Classi pre-estratte**: Sì, in `/api/classes/` tramite COPY
- **Agent version**: 0.8.7

### Avvio dell'API

```bash
/usr/local/tomcat/bin/catalina.sh run > /results/$API/$TOOL/$RUN/logs/alfresco-stdout.log 2> /results/$API/$TOOL/$RUN/logs/alfresco-stderr.log &

# Wait for Alfresco to be ready (fino a 180 secondi)
for i in {1..180}; do
  if curl -s -u admin:admin http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready- > /dev/null 2>&1; then
    echo "Alfresco is ready!"
    break
  fi
  sleep 1
done
```

**Health check**: `/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-`

### Particolarità

1. **Sistema complesso**: Alfresco è un'applicazione enterprise molto pesante con Tomcat, PostgreSQL, e numerosi servizi interni
2. **Tempo di avvio lungo**: Richiede fino a 3 minuti per essere completamente operativo
3. **Indice disabilitato**: `-Dindex.subsystem.name=noindex` per velocizzare l'avvio (non serve Solr per i test)
4. **Trasformazioni disabilitate**: Transform service non necessario per i test REST
5. **CSRF disabilitato**: `-Dcsrf.filter.enabled=false` per facilitare il testing
6. **PostgreSQL embedded**: Il database viene installato e gestito nello stesso container per semplicità

### Porte Esposte
- **8080**: API Alfresco (Tomcat)
- **9090**: Mitmproxy
- **12345**: JaCoCo

---

## 5.16 Gestão Hospitalar

### Descrizione
Sistema di gestione ospedaliera sviluppato in Spring Boot con MongoDB. Gestisce ospedali, pazienti, prodotti e ubicazioni con supporto per ricerche geospaziali.

### Dockerfile
```dockerfile
FROM ubuntu:22.04
```

**Caratteristiche principali**:
- **Java**: OpenJDK 8
- **Database**: MongoDB 6.0
- **File JAR**: gestaohospitalar-0.0.1.jar
- **Memoria JVM**: Default (nessuna limitazione esplicita)

### Database: MongoDB

**Installazione**:
```bash
# Add MongoDB official repository
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update && apt-get -y install mongodb-org
```

**Avvio e inizializzazione**:
```bash
# Start MongoDB in background
mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db
sleep 10

# Initialize database with test data
if [ -f /api/database/init-mongo.js ]; then
  mongo HospitalDB /api/database/init-mongo.js
fi
```

**Script di inizializzazione**: `init-mongo.js`

Crea e popola 4 collection:
- **hospitals**: Dati di 5 ospedali di esempio con coordinate GPS
- **patients**: 10 pazienti con dati clinici
- **products**: 8 prodotti farmaceutici con prezzi e quantità
- **locations**: 6 località con coordinate geospaziali

Esempio:
```javascript
db.hospitals.insertMany([
    {
        nome: "Hospital Municipal Central",
        endereco: "Rua das Flores, 100",
        cidade: "São Paulo",
        location: {
            type: "Point",
            coordinates: [-46.6333, -23.5505]
        },
        leitos: 250,
        vagasDisponiveis: 45,
        ativo: true
    }
]);
```

### Autenticazione

**Script**: `auth.py`

**Modalità**: Session-based con signup

```python
class GestaoHospitalarAuth:
    def get_token(self):
        # 1. Register user
        signup_url = f"{self.base_url}/register"
        signup_payload = {
            "email": "restapitestteam@gmail.com",
            "password": "universe"
        }
        
        # 2. Login to get session token
        login_url = f"{self.base_url}/login"
        # Returns JWT token
```

Le richieste successive usano il token JWT nell'header `Authorization: Bearer {token}`.

### JaCoCo

```bash
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -jar /api/gestaohospitalar.jar
```

- **Pattern coverage**: `*` (tutte le classi)
- **Classi estratte**: Sì, in `/api/classes/`

### Avvio dell'API

```bash
java -Dserver.port=8080 \
     -Dspring.data.mongodb.host=localhost \
     -Dspring.data.mongodb.port=27017 \
     -Dspring.data.mongodb.database=HospitalDB \
     -jar /api/gestaohospitalar.jar

# Health check su un endpoint di esempio
curl -s http://localhost:8080/v1/hospitais/
```

### Particolarità

1. **Ricerca geospaziale**: L'API supporta query basate su coordinate geografiche
2. **MongoDB come documento store**: Usa collezioni NoSQL invece di tabelle relazionali
3. **Dati in portoghese**: Tutti i nomi di campi e dati di test sono in portoghese brasiliano
4. **Java 8**: Richiede OpenJDK 8 per compatibilità con dipendenze legacy

### Porte Esposte
- **8080**: API REST
- **9090**: Mitmproxy
- **12345**: JaCoCo

---

## 5.17 NoteBook Manager

### Descrizione
API semplice per la gestione di notebook (prodotti) con operazioni CRUD. Sviluppata in Spring Boot con database MySQL.

### Dockerfile
```dockerfile
FROM ubuntu:22.04
```

**Caratteristiche principali**:
- **Java**: OpenJDK 11
- **Database**: MySQL 8.0
- **File JAR**: notebookmanager.jar
- **Memoria JVM**: Default

### Database: MySQL

**Installazione**:
```bash
apt -y install mysql-server
```

**Avvio e inizializzazione**:
```bash
# Start MySQL
service mysql start

# Wait for MySQL to be ready
until mysqladmin ping -h localhost --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done

# Set root password (MySQL 8.0 requires authentication)
mysql --user=root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123';
    FLUSH PRIVILEGES;
EOSQL

# Create database
mysql --user=root --password=root123 <<-EOSQL
    DROP DATABASE IF EXISTS notebook_manager;
    CREATE DATABASE notebook_manager;
EOSQL

# Import schema and data
mysql --user=root --password=root123 notebook_manager < /api/database/schema.sql
mysql --user=root --password=root123 notebook_manager < /api/database/data.sql
```

**Schema**: `schema.sql`
```sql
CREATE TABLE IF NOT EXISTS note_book (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NULL,
    current_price DOUBLE NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Dati**: `data.sql`
Popola la tabella con notebook di esempio (Dell, HP, Lenovo, ecc.) con prezzi.

### Autenticazione

**Nessuna autenticazione richiesta**: L'API è pubblica e non richiede credenziali.

### JaCoCo

```bash
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -jar /api/notebookmanager.jar
```

- **Pattern coverage**: `*` (tutte le classi)
- **Classi estratte**: Sì, in `/api/classes/`

### Avvio dell'API

```bash
java -Dserver.port=8080 \
     -Dspring.datasource.url=jdbc:mysql://localhost:3306/notebook_manager?createDatabaseIfNotExist=true\&useSSL=false\&allowPublicKeyRetrieval=true \
     -Dspring.datasource.username=root \
     -Dspring.datasource.password=root123 \
     -Dspring.jpa.hibernate.ddl-auto=none \
     -jar /api/notebookmanager.jar
```

**Note**:
- `-Dspring.jpa.hibernate.ddl-auto=none`: Disabilita auto-DDL, usa gli script SQL espliciti
- `allowPublicKeyRetrieval=true`: Necessario per MySQL 8.0+ con autenticazione

### Particolarità

1. **API semplicissima**: Solo operazioni CRUD su una singola entità
2. **MySQL 8.0**: Richiede configurazione esplicita della password root con `mysql_native_password`
3. **No autenticazione**: Endpoint pubblici senza sicurezza
4. **Clean state**: Il database viene ricreato (DROP/CREATE) ad ogni avvio per garantire stato pulito

### Porte Esposte
- **8080**: API REST (non esplicitamente EXPOSE nel Dockerfile, ma usata)
- **9090**: Mitmproxy (non esplicitamente EXPOSE nel Dockerfile, ma usata)
- **12345**: JaCoCo (non esplicitamente EXPOSE nel Dockerfile, ma usata)

**Nota**: Il Dockerfile non contiene direttive EXPOSE, ma le porte vengono usate comunque.

---

### 6.5 Prossimi Sviluppi

1. Integrazione con orchestratori (Kubernetes)
2. Ottimizzazione memoria per esecuzioni parallele
3. Cache layer per dipendenze pesanti (Maven, npm)
4. Monitoring real-time con Prometheus/Grafana
5. Automated scaling basato su load testing

---

## Appendice A: Riferimenti Tecnici

### Tool e Framework
- **RESTgym**: https://github.com/codingsoo/RESTgym
- **RESTTestGen**: https://github.com/SeUniVr/RESTTestGen
- **JaCoCo**: https://www.jacoco.org/
- **Mitmproxy**: https://mitmproxy.org/
- **OpenAPI Specification**: https://spec.openapis.org/oas/v3.0.3

### Documentazione API
- Traccar: https://www.traccar.org/api-reference/
- Flowable: https://www.flowable.com/open-source/docs/
- Nexus: https://help.sonatype.com/repomanager3/rest-and-integration-api
- PetClinic: https://github.com/spring-petclinic/spring-petclinic-rest
- Gravitee: https://docs.gravitee.io/apim/3.x/
- Kafka REST: https://docs.confluent.io/platform/current/kafka-rest/
- Keycloak: https://www.keycloak.org/docs/latest/

---

**Fine Documento**  
*Versione 1.0 - Dicembre 2025*
