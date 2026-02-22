
Grafana Monitoring Stack

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white)](https://grafana.com)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white)](https://prometheus.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Production-ready monitoring stack using Grafana, Prometheus, and Alertmanager. Deployed for healthcare infrastructure monitoring.

## 🎯 Overview

This repository contains a complete monitoring solution designed for production environments, specifically tailored for digital health infrastructure. It includes pre-configured dashboards for monitoring:

- Web application uptime and response times
- Database performance metrics
- Server resource utilization (CPU, Memory, Disk)
- Custom application metrics
- Alerting rules for critical incidents

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web App       │────▶│  Prometheus     │────▶│   Grafana       │
│   (Target)      │     │  (Metrics DB)   │     │   (Dashboards)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  Alertmanager   │
                        │  (Notifications)│
                        └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Valmoe/grafana-monitoring-stack.git
   cd grafana-monitoring-stack
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Deploy the stack**
   ```bash
   docker-compose up -d
   ```

4. **Access Grafana**
   - URL: http://localhost:3000
   - Default credentials: admin/admin
   - Change password on first login

## 📊 Included Dashboards

### 1. Web Application Monitoring
- **Purpose**: Monitor website uptime and performance
- **Metrics**: Response time, status codes, throughput
- **Alerts**: High response time, 5xx errors

### 2. Database Performance
- **Purpose**: PostgreSQL/MySQL performance tracking
- **Metrics**: Query duration, connections, slow queries
- **Alerts**: High connection count, slow query detection

### 3. System Resources
- **Purpose**: Server health monitoring
- **Metrics**: CPU, Memory, Disk I/O, Network
- **Alerts**: High resource utilization

## 🔧 Configuration

### Adding New Targets

Edit `prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-application'
    static_configs:
      - targets: ['app-host:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### Custom Alert Rules

Add rules to `prometheus/rules/custom.yml`:

```yaml
groups:
  - name: custom_rules
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
```

## 🚨 Alerting Channels

Configured notification channels:
- 📧 Email (SMTP)
- 💬 Slack
- 📱 PagerDuty
- 🎫 ServiceNow

## 📁 Repository Structure

```
.
├── docker-compose.yml          # Main orchestration file
├── .env.example               # Environment variables template
├── grafana/
│   ├── dashboards/            # JSON dashboard definitions
│   ├── datasources/           # Data source configurations
│   └── provisioning/          # Auto-provisioning configs
├── prometheus/
│   ├── prometheus.yml         # Main configuration
│   └── rules/                 # Alert rules
├── alertmanager/
│   └── config.yml             # Alert routing
└── assets/                    # Screenshots and docs
```

## 🛡️ Security Best Practices

- ✅ Non-root container execution
- ✅ Secrets management via environment variables
- ✅ Network isolation with Docker networks
- ✅ TLS/SSL for external endpoints
- ✅ Regular base image updates

## 📝 Lessons Learned

Key insights from production deployments:

1. **Retention Strategy**: 15-day local retention with S3 backup for compliance
2. **High Availability**: Prometheus federation for multi-region setups
3. **Alert Fatigue**: Implemented alert grouping and inhibition rules
4. **Performance**: Recording rules for frequently queried metrics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

Valentine Gumo - [gumovalentine@gmail.com](mailto:gumovalentine@gmail.com)

Project Link: [https://github.com/Valmoe/grafana-monitoring-stack](https://github.com/Valmoe/grafana-monitoring-stack)

---

⭐ Star this repository if you find it helpful!
''',

    'docker-compose.yml': '''version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.0.0
    container_name: grafana
    restart: unless-stopped
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=${GRAFANA_ROOT_URL:-http://localhost:3000}
    ports:
      - "3000:3000"
    networks:
      - monitoring
    depends_on:
      - prometheus

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: alertmanager
    restart: unless-stopped
    volumes:
      - ./alertmanager/config.yml:/etc/alertmanager/config.yml:ro
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.6.0
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

networks:
  monitoring:
    driver: bridge
''',

    'prometheus/prometheus.yml': '''global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']

  # Example: Web application monitoring
  # - job_name: 'web-app'
  #   static_configs:
  #     - targets: ['web-app:8080']
  #   metrics_path: '/actuator/prometheus'
''',

    'prometheus/rules/alerts.yml': '''groups:
  - name: infrastructure
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85% for more than 5 minutes"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Disk space is below 10%"

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "{{ $labels.job }} service is down"
''',

    '.env.example': '''# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=changeme
GRAFANA_ROOT_URL=http://localhost:3000

# Alertmanager Configuration
SMTP_FROM=alerts@example.com
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_AUTH_USERNAME=your-email@gmail.com
SMTP_AUTH_PASSWORD=your-app-password

# Slack Integration
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
''',

    'LICENSE': '''MIT License

Copyright (c) 2026 Valentine Gumo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.