# RESTgym

Infrastructure per testing automatico di API REST.

## Features

- Esecuzione automatica sessioni di test (tool × API × run)
- Parallelizzazione con controllo risorse (CPU/RAM)
- Collection dati: coverage, operation coverage, fault detection
- Health check runtime
- Integrity check e re-esecuzione automatica sessioni corrotte
- Report completi per sessione + report cumulativo

## Installation

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Configuration

### `restgym-config.yml`

```yaml
minimum_cpus: 4
minimum_ram_gb: 4
```

### API/Tool config

File `restgym-api-config.yml` e `restgym-tool-config.yml`:

```yaml
enabled: true  # false per escludere
```

Default: DeepREST, RESTler, Market, SCS abilitati.

## Usage

### 1. Build Docker images

```bash
python3 build.py
```

Build locale + download da Docker Hub (https://hub.docker.com/u/restgym).

### 2. Run esperimenti

```bash
python3 run.py
```

Prompt per numero ripetizioni, esegue sessioni mancanti.

Output: `results/<api>/<tool>/<run>/`

### 3. Check integrity

```bash
python3 check.py
```

Verifica metriche, requests proxy, coverage crescente. Prompt per eliminare sessioni corrotte.

### 4. Process results

```bash
python3 process_results.py
```

Output:
- JSON report per ogni esecuzione
- CSV cumulativo in `results/`

## Estensioni

Template in `apis/#api-template` e `tools/#tool-template`.

---

Repository: [RESTgym paper/documentation]
