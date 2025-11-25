# Verifica Completa - Sistema Gestão Hospitalar (gestaohospitalar)

**Data**: 24 Novembre 2025  
**API**: Sistema de Gestão Hospitalar  
**Versione**: 0.0.1  
**Framework**: Spring Boot 2.1.3 + MongoDB

---

## ✅ Stato Generale: **COMPLETAMENTE OPERATIVO**

Tutti i componenti del sistema RESTgym sono stati dockerizzati correttamente e funzionano come previsto.

---

## 📊 Riepilogo Verifica

### 1. **Compilazione Java**
- ✅ Maven build: **SUCCESSO**
- ✅ JAR creato: `gestaohospitalar-0.0.1.jar` (25.4 MB)
- ✅ Classes estratte: **34 file .class**
- ✅ Bug fixati:
  - Duplicate `@Autowired` in `HospitalService.java`
  - MongoDB URI hardcoded → configurazione environment-based

### 2. **Struttura RESTgym**
```
gestaohospitalar/
├── Dockerfile                     ✅ Creato
├── docker-compose.yml             ✅ Creato
├── restgym-api-config.yml         ✅ Creato
├── gestaohospitalar-0.0.1.jar     ✅ Copiato
├── specifications/
│   └── gestaohospitalar-openapi.yaml ✅ Copiato
├── classes/
│   └── br/com/codenation/hospital/**/*.class ✅ 34 file
├── dictionaries/deeprest/
│   └── gestaohospitalar.json      ✅ Creato (100+ valori)
├── database/
│   └── init-mongo.js              ✅ Creato (con sample data)
└── infrastructure/
    ├── jacoco/
    │   ├── org.jacoco.agent-0.8.7-runtime.jar ✅
    │   ├── org.jacoco.cli-0.8.7-nodeps.jar   ✅
    │   └── collect-coverage-interval.sh       ✅
    └── mitmproxy/
        └── store-interactions.py              ✅
```

### 3. **Build Docker**
- ✅ Immagine: `gestaohospitalar-api:latest`
- ✅ Base: Ubuntu 22.04
- ✅ Java: OpenJDK 8
- ✅ Componenti: mitmproxy, JaCoCo, MongoDB client
- ✅ Tempo build: ~5 minuti (primo build con dipendenze)

### 4. **Container Runtime**
```
CONTAINER                      STATUS                PORTS
gestaohospitalar-restgym       Up (healthy)          8080, 9090, 12345
gestaohospitalar-mongodb       Up (healthy)          27017
```

### 5. **Test API via mitmproxy (porta 9090)**
**Endpoint testato**: `GET http://localhost:9090/v1/hospitais/`

**Response (200 OK)**:
```json
[
  {
    "id": 1,
    "name": "Hospital Israelita Albert Einstein",
    "address": "Av. Albert Einstein, 627 - Jardim Leonor, São Paulo - SP, 05652-900",
    "beds": 21,
    "availableBeds": 5,
    "longitude": -46.6388042029871,
    "latitude": -23.5920091
  },
  {
    "id": 2,
    "name": "Hospital São Luiz Unidade Morumbi",
    "address": "Rua Engenheiro Oscar Americano, 840 - Jardim Guedala, São Paulo - SP",
    "beds": 11,
    "availableBeds": 6,
    "longitude": -46.703459,
    "latitude": -23.591093
  },
  {
    "id": 3,
    "name": "Hospital Next Butantã",
    "address": "Av. Prof. Francisco Morato, 719 - Butantã, São Paulo - SP",
    "beds": 32,
    "availableBeds": 12,
    "longitude": -46.708343,
    "latitude": -23.578151
  }
]
```

### 6. **mitmproxy - Registrazione Interazioni**
- ✅ Porta: **9090** (reverse proxy a http://localhost:8080)
- ✅ Script: `/infrastructure/mitmproxy/store-interactions.py`
- ✅ Database: `/results/gestaohospitalar/manual/1/results.db`
- ✅ **Interazioni registrate**: **1**
  - Tabella `interactions` popolata correttamente
  - Campi: timestamp, method, url, path, request_headers, request_body, status_code, response_headers, response_body, duration_ms

**Query verifica**:
```sql
SELECT COUNT(*) FROM interactions;
-- Output: 1
```

### 7. **JaCoCo - Code Coverage**
- ✅ Porta: **12345** (TCP server attivo)
- ✅ Agent: `/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar`
- ✅ CLI: `/infrastructure/jacoco/org.jacoco.cli-0.8.7-nodeps.jar`
- ✅ Script: `/infrastructure/jacoco/collect-coverage-interval.sh` (polling ogni 5 sec)
- ✅ **File .exec generati**: **24**
  - Directory: `/results/gestaohospitalar/manual/1/code-coverage/`
  - Formato: `jacoco_YYYY-MM-DDTHH.MM.SS.exec`

**Test connessione**:
```powershell
Test-NetConnection -ComputerName localhost -Port 12345
# TcpTestSucceeded: True ✅
```

### 8. **MongoDB**
- ✅ Versione: **4.4**
- ✅ Database: `HospitalDB`
- ✅ Collections:
  - `hospitals` (3 ospedali)
  - `patients` (3 pazienti)
  - `products` (4 prodotti medici)
  - `locations` (3 strutture sanitarie)
- ✅ Geospatial indexes: attivi su `hospitals.location` e `locations.location`
- ✅ Init script: `/database/init-mongo.js` eseguito al primo avvio

---

## 🔍 Verifica Dettagliata Componenti

### JaCoCo Agent
```
Configurazione:
  includes=*
  output=tcpserver
  port=12345
  address=* (tutti gli indirizzi)

Comando Java:
  -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=*
```

### mitmproxy
```
Configurazione:
  Porta: 9090
  Modalità: reverse proxy
  Target: http://localhost:8080/
  Script: /infrastructure/mitmproxy/store-interactions.py

Database SQLite:
  Path: /results/gestaohospitalar/manual/1/results.db
  Schema:
    - id (INTEGER PRIMARY KEY AUTOINCREMENT)
    - timestamp (TEXT NOT NULL)
    - method (TEXT NOT NULL)
    - url (TEXT NOT NULL)
    - path (TEXT NOT NULL)
    - request_headers (TEXT)
    - request_body (TEXT)
    - status_code (INTEGER)
    - response_headers (TEXT)
    - response_body (TEXT)
    - duration_ms (INTEGER)
```

### Spring Boot Application
```
Porta interna: 8080
Porta proxy: 9090
MongoDB: mongodb:27017

Configurazione (application.properties):
  spring.data.mongodb.host=${SPRING_DATA_MONGODB_HOST:localhost}
  spring.data.mongodb.port=${SPRING_DATA_MONGODB_PORT:27017}
  spring.data.mongodb.database=${SPRING_DATA_MONGODB_DATABASE:HospitalDB}

Variabili d'ambiente (docker-compose.yml):
  SPRING_DATA_MONGODB_HOST=mongodb
  SPRING_DATA_MONGODB_PORT=27017
  SPRING_DATA_MONGODB_DATABASE=HospitalDB
```

---

## 📝 Note Tecniche

### Issue Risolti Durante Setup

1. **Compilation Error: Duplicate @Autowired**
   - File: `HospitalService.java` (linee 43-44)
   - Fix: Rimozione dichiarazione duplicata di `locationService`

2. **MongoDB Connection Failed**
   - Problema: URI hardcoded `mongodb://localhost:27017/HospitalDB`
   - Fix: Configurazione basata su variabili d'ambiente
   - Prima: `spring.data.mongodb.uri=mongodb://localhost:27017/HospitalDB`
   - Dopo:
     ```properties
     spring.data.mongodb.host=${SPRING_DATA_MONGODB_HOST:localhost}
     spring.data.mongodb.port=${SPRING_DATA_MONGODB_PORT:27017}
     spring.data.mongodb.database=${SPRING_DATA_MONGODB_DATABASE:HospitalDB}
     ```

3. **Docker Build Time**
   - Primo build: ~6 minuti (scaricamento dipendenze apt)
   - Build successivi: ~15 secondi (cache Docker layers)

---

## 🚀 Comandi Utilizzo

### Avvio Sistema
```powershell
cd f:\Desktop\Tesi-RESTAPI\RESTgym\apis\gestaohospitalar
docker-compose up -d
```

### Verifica Stato
```powershell
docker ps --filter "name=gestaohospitalar"
```

### Test API
```powershell
# Via mitmproxy (registra interazioni)
Invoke-RestMethod -Uri "http://localhost:9090/v1/hospitais/" -Method GET

# Diretto all'API (no registrazione)
Invoke-RestMethod -Uri "http://localhost:8080/v1/hospitais/" -Method GET
```

### Verifica Interazioni
```powershell
docker exec gestaohospitalar-restgym sqlite3 /results/gestaohospitalar/manual/1/results.db "SELECT method, path, status_code FROM interactions;"
```

### Verifica Coverage
```powershell
docker exec gestaohospitalar-restgym ls -lh /results/gestaohospitalar/manual/1/code-coverage/
```

### Logs
```powershell
docker logs gestaohospitalar-restgym --tail 100
docker logs gestaohospitalar-mongodb --tail 100
```

### Stop Sistema
```powershell
docker-compose down
# Per rimuovere anche i volumi MongoDB:
docker-compose down -v
```

---

## 📈 Endpoints Disponibili

Tutti accessibili via `http://localhost:9090` (mitmproxy) o `http://localhost:8080` (diretto):

### Hospitals
- `GET /v1/hospitais/` - Lista ospedali
- `POST /v1/hospitais/` - Crea ospedale
- `GET /v1/hospitais/{id}` - Dettagli ospedale
- `PUT /v1/hospitais/{id}` - Aggiorna ospedale
- `DELETE /v1/hospitais/{id}` - Elimina ospedale

### Inventory
- `GET /v1/hospitais/{id}/estoque` - Lista inventario
- `POST /v1/hospitais/{id}/estoque` - Aggiungi prodotto
- `PUT /v1/hospitais/{id}/estoque/{productId}` - Aggiorna prodotto
- `DELETE /v1/hospitais/{id}/estoque/{productId}` - Rimuovi prodotto

### Patients
- `POST /v1/hospitais/{id}/pacientes` - Check-in paziente
- `DELETE /v1/hospitais/{id}/pacientes/{patientId}` - Check-out paziente
- `GET /v1/hospitais/{id}/pacientes` - Lista pazienti

### Locations
- `GET /v1/hospitais/{id}/proximidades` - Strutture vicine (geospatial query)

---

## ✨ Conclusioni

Il sistema **Sistema de Gestão Hospitalar** è stato **dockerizzato con successo** seguendo esattamente il template RESTgym:

✅ **Build**: Maven package completato senza errori  
✅ **Docker**: Immagine creata e container avviati  
✅ **API**: REST endpoints funzionanti (testato GET /v1/hospitais/)  
✅ **Database**: MongoDB inizializzato con sample data  
✅ **mitmproxy**: Interazioni registrate correttamente in SQLite  
✅ **JaCoCo**: Code coverage attivo e file .exec generati  
✅ **Monitoring**: Tutti i container healthy  

Il sistema è ora pronto per essere utilizzato nei processi di **fuzzing automatico** e **testing** di RESTgym.

---

**Prossimi Step Consigliati**:
1. Eseguire test completi su tutti gli endpoint dell'API
2. Analizzare i dati di coverage con JaCoCo report generator
3. Utilizzare il dictionary per fuzzing con DeepREST
4. Verificare comportamento sotto carico con più richieste concorrenti
5. Documentare eventuali edge cases trovati durante i test

---

**Fine Verifica** ✅
