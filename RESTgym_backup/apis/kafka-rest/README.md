# Kafka REST - RESTgym Integration

Kafka REST Proxy con JaCoCo code coverage per RESTgym.

## Come è stato ottenuto il JAR

Kafka REST è distribuito come binario pre-compilato da Confluent. Non serve buildarlo:

1. **Immagine ufficiale**: Usata `confluentinc/cp-kafka-rest:7.5.0`
2. **JAR location**: `/usr/share/java/kafka-rest-lib/kafka-rest-7.5.0.jar`
3. **Classi estratte**: 818 classi dal JAR con `unzip`

## Build Docker Image

```bash
cd /path/to/Tesi-RESTAPI/RESTgym

# Build con estrazione classi automatica
docker build -f apis/kafka-rest/Dockerfile -t restgym-kafka-rest:latest .
```

Tempo: ~5 minuti. Output: 1.25GB con 818 classi estratte.

## Avvio Stack Completo

Kafka REST richiede 4 servizi (Zookeeper, Kafka, Schema Registry, REST Proxy):

```bash
cd apis/kafka-rest

# Avvia tutto
TOOL=test RUN=1 docker compose up -d

# Attendi ~30 secondi che tutti i servizi siano healthy
docker compose ps

# Verifica
curl http://localhost:9090/  # MITMProxy (usa questa)
curl http://localhost:8082/  # Diretta
```

## Test API

```bash
# Via MITMProxy (RESTgym standard - porta 9090)
curl http://localhost:9090/
curl http://localhost:9090/brokers
curl http://localhost:9090/topics
```

## Stop

```bash
docker compose down
```

## Porte

- **9090**: MITMProxy (API per testing - **USA QUESTA**)
- **8082**: Kafka REST diretta
- **12345**: JaCoCo TCP server
- **8081**: Schema Registry
- **9092**: Kafka Broker
- **2181**: Zookeeper

## Risultati

Salvati in: `../../results/kafka-rest/$TOOL/$RUN/`
- `code-coverage/*.exec` - JaCoCo coverage (ogni 5 sec)
- `results.db` - SQLite con HTTP interactions

## Note

- Kafka REST usa porta **8082** (non 8080)
- Richiede **Docker Compose** (non funziona standalone)
- Startup: ~30 secondi (per tutte le dipendenze)
- RAM necessaria: ~3GB per lo stack completo

## Struttura

```
apis/kafka-rest/
├── Dockerfile              # Build con JaCoCo
├── docker-compose.yml      # Stack completo (4 servizi)
├── restgym-api-config.yml # enabled: true
├── specifications/         # OpenAPI specs
└── README.md              # Questo file
```
