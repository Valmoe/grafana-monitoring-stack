# Grafana Monitoring Stack

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)
[![Grafana](https://img.shields.io/badge/Grafana-10.4.3-F46800?style=flat-square&logo=grafana&logoColor=white)](https://grafana.com)
[![Prometheus](https://img.shields.io/badge/Prometheus-v2.45.0-E6522C?style=flat-square&logo=prometheus&logoColor=white)](https://prometheus.io)
[![Alertmanager](https://img.shields.io/badge/Alertmanager-v0.27.0-E6522C?style=flat-square)](https://prometheus.io/docs/alerting/alertmanager/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Production-ready self-hosted monitoring stack using Grafana, Prometheus, Alertmanager, and Node Exporter. Fully provisioned with dashboards, alert rules, and email notifications out of the box.

---

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │         Docker Network: monitoring       │
                    │                                         │
  Host System       │  ┌──────────────┐    ┌───────────────┐ │
  /proc /sys /  ────┼─▶│ node-exporter│    │  Prometheus   │ │
                    │  │   :9100      │───▶│    :9090      │ │
                    │  └──────────────┘    │               │ │
                    │                      │ scrapes all 4 │ │
                    │  ┌──────────────┐    │ targets every │ │
                    │  │   Grafana    │◀───│    15s        │ │
                    │  │    :3000     │    │               │ │
                    │  └──────────────┘    │ evaluates     │ │
                    │                      │ rules every   │ │
                    │  ┌──────────────┐◀───│    15s        │ │
                    │  │ Alertmanager │    └───────────────┘ │
                    │  │    :9093     │                       │
                    │  └──────┬───────┘                       │
                    └─────────┼───────────────────────────────┘
                              │ Gmail SMTP :587
                    ┌─────────▼──────────────┐
                    │  warning → team inbox  │
                    │  critical → on-call    │
                    └────────────────────────┘
```

All ports are bound to `127.0.0.1` (loopback only) — nothing is exposed to the public internet directly. Place a reverse proxy (nginx, Caddy) in front of Grafana for external access.

---

## What's Included

### Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| Prometheus | `prom/prometheus:v2.45.0` | 9090 | Metrics collection and storage |
| Grafana | `grafana/grafana:10.4.3` | 3000 | Dashboards and visualisation |
| Alertmanager | `prom/alertmanager:v0.27.0` | 9093 | Alert routing and email notifications |
| Node Exporter | `prom/node-exporter:v1.6.0` | 9100 | Host system metrics |

### Dashboards (auto-provisioned)

| Dashboard | Panels | Coverage |
|-----------|--------|----------|
| Node Exporter — Host Metrics | 12 | CPU by mode, load vs cores, memory breakdown, disk space, disk I/O, network traffic, network errors |
| Prometheus — Self Monitoring | 10 | Target health table, scrape duration, sample counts, rule evaluation, TSDB internals, ingestion rate |
| Alertmanager — Alert Pipeline | 10 | Firing/pending alerts, severity breakdown, live alert table, notification pipeline, dispatcher health |

### Alert Rules (10 rules across 2 severity tiers)

| Alert | Threshold | Severity |
|-------|-----------|----------|
| HighCPUUsageWarning | > 80% for 5m | warning |
| HighCPUUsageCritical | > 95% for 5m | critical |
| HighMemoryUsageWarning | > 85% for 5m | warning |
| HighMemoryUsageCritical | > 95% for 2m | critical |
| DiskSpaceWarning | < 20% for 5m | warning |
| DiskSpaceCritical | < 10% for 5m | critical |
| DiskFillingUp | fills in < 4h | warning |
| ServiceDown | up == 0 for 1m | critical |
| HighLoadAverage | > 80% of cores for 5m | warning |
| NetworkReceiveErrors | errors > 0 for 5m | warning |

**Inhibition rules:** Critical suppresses its matching warning. `ServiceDown` suppresses all other alerts for that instance to prevent noise storms.

---

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- A Gmail account with [App Password](https://myaccount.google.com/apppasswords) enabled

### 1. Clone

```bash
git clone https://github.com/Valmoe/grafana-monitoring-stack.git
cd grafana-monitoring-stack
```

### 2. Configure environment

```bash
cp .env.example .env
# Fill in your values — see .env.example for full documentation
```

The required variables are:

```dotenv
GRAFANA_ADMIN_PASSWORD=        # Strong random password
GF_SERVER_DOMAIN=              # e.g. localhost (or grafana.example.com in production)
GF_SERVER_ROOT_URL=            # e.g. http://localhost:3000
SMTP_FROM=                     # Your Gmail address
SMTP_USERNAME=                 # Your Gmail address
SMTP_PASSWORD=                 # Gmail App Password (16 chars)
ALERT_EMAIL_TO=                # Warning alert recipient
ALERT_EMAIL_TO_CRITICAL=       # Critical alert recipient
```

### 3. Render Alertmanager config

Alertmanager reads a static config file. Run this once after filling in `.env`, and again any time `.env` changes:

```bash
# Fix line endings if on Windows/WSL first
sed -i 's/\r//' .env
sed -i 's/\r//' render-config.sh

sh render-config.sh
```

### 4. Start the stack

```bash
docker compose up -d

# Watch startup
docker compose logs -f

# Check all services are healthy
docker compose ps
```

### 5. Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / your `GRAFANA_ADMIN_PASSWORD` |
| Prometheus | http://localhost:9090 | — |
| Alertmanager | http://localhost:9093 | — |

---

## Repository Structure

```
.
├── docker-compose.yml              # Orchestration — all 4 services
├── render-config.sh                # Renders alertmanager config template
├── .env.example                    # Environment variable reference (safe to commit)
├── .env                            # Your real secrets (gitignored)
├── .gitignore
│
├── prometheus/
│   ├── prometheus.yml              # Scrape configs, Alertmanager connection
│   └── rules/
│       └── infrastructure.yml      # 10 alert rules
│
├── alertmanager/
│   ├── config.yml.tmpl             # Alert routing + HTML email templates (template)
│   └── config.yml                  # Rendered at runtime by render-config.sh (gitignored)
│
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── prometheus.yml      # Auto-wires Prometheus as default datasource
    │   └── dashboards/
    │       └── dashboards.yml      # Tells Grafana where to load dashboard JSONs
    └── dashboards/
        ├── node-exporter.json      # Host metrics dashboard
        ├── prometheus.json         # Prometheus self-monitoring dashboard
        └── alertmanager.json       # Alert pipeline dashboard
```

---

## Configuration

### Adding a new scrape target

Edit `prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-application'
    static_configs:
      - targets: ['app-hostname:8080']
        labels:
          service: 'my-application'
    metrics_path: '/metrics'
    scrape_interval: 15s
```

Then reload Prometheus without restarting:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Adding a new alert rule

Add a file to `prometheus/rules/` — it will be picked up automatically on next reload:

```yaml
groups:
  - name: my-app
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
          team: ops
        annotations:
          summary: "High error rate on {{ $labels.instance }}"
          description: "5xx rate is {{ $value | printf \"%.2f\" }} req/s"
          runbook_url: "https://example.com/runbooks/high-error-rate"
```

### Updating secrets

```bash
# Edit .env, then re-render and restart alertmanager
sh render-config.sh
docker compose restart alertmanager
```

---

## Security

- All ports bound to `127.0.0.1` — not exposed to public internet
- All containers run as non-root users
- `no-new-privileges` set on all services
- Secrets managed via `.env` (gitignored) — no hardcoded credentials anywhere
- `alertmanager/config.yml` (contains rendered SMTP password) is gitignored
- Grafana sign-up disabled, cookie security enabled
- Grafana analytics and telemetry reporting disabled

---

## Production Deployment Notes

When moving from local to a real server:

1. Update `GF_SERVER_DOMAIN` and `GF_SERVER_ROOT_URL` in `.env` to your real domain
2. Set `GF_SECURITY_COOKIE_SECURE=true` (already set) — requires HTTPS
3. Put Grafana behind a reverse proxy (nginx/Caddy) with TLS — do not expose port 3000 directly
4. Consider increasing `PROMETHEUS_RETENTION` (e.g. `30d` or `90d`)
5. Set up volume backups — all persistent data lives in named Docker volumes

---

## License

MIT License — see [LICENSE](LICENSE)

## Contact

Valentine Gumo — [gumovalentine@gmail.com](mailto:gumovalentine@gmail.com)

Project: [https://github.com/Valmoe/grafana-monitoring-stack](https://github.com/Valmoe/grafana-monitoring-stack)