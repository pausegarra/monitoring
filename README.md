# monitoring

Monitoring stack based on Prometheus, Grafana, Loki, and Alloy.

## What it includes

- `Grafana` with provisioned dashboards, alerts, and datasources baked into the custom image.
- `Prometheus` with scrape configuration defined in `config/prometheus.yaml`.
- `Loki` for log storage.
- `Alloy` as the OTLP collector receiving logs and forwarding them to Loki.
- `Blackbox Exporter`, `nginx-prometheus-exporter`, and `cadvisor`.

## Structure

- `compose.yaml`: production stack using `ghcr.io/pausegarra/...:${VERSION}` images.
- `compose.local.yaml`: local stack using public images.
- `Dockerfile.grafana`
- `Dockerfile.prometheus`
- `Dockerfile.blackbox`
- `Dockerfile.loki`
- `Dockerfile.alloy`
- `config/alloy-config.alloy`: OTLP receiver on `4317`/`4318` forwarding logs to Loki.
- `config/loki-config.yaml`: Loki single-binary configuration.

## Production

Production deployment uses `compose.yaml` and expects these environment variables:

- `VERSION`
- `EMAIL_USERNAME`
- `EMAIL_PASSWORD`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_CLIENT_SECRET`

Exposed ports:

- Grafana: `3030`
- Prometheus: `9090`
- Loki: `3100`
- Alloy internal HTTP endpoint: `12345`
- Alloy OTLP gRPC: `4317`
- Alloy OTLP HTTP: `4318`

Grafana provisions:

- Prometheus as the default datasource
- Loki as the logs datasource
- dashboards from `dashboards/`
- alerting resources from `alerting/`

## Local

To start the local stack:

```bash
docker compose -f compose.local.yaml up -d
```

The local compose uses public images and is intended for validating connectivity and log ingestion. It does not fully replicate the provisioned Grafana setup used in production.

Local endpoints:

- Grafana: `http://localhost:3030`
- Prometheus: `http://localhost:9090`
- Loki: `http://localhost:3100`
- Alloy OTLP gRPC: `localhost:4317`
- Alloy OTLP HTTP: `http://localhost:4318`

Default local Grafana credentials:

- username: `admin`
- password: `admin`

You can override them when starting the stack:

```bash
GRAFANA_ADMIN_USER=admin GRAFANA_ADMIN_PASSWORD=secret docker compose -f compose.local.yaml up -d
```

## Manual build

Available targets in `Makefile`:

```bash
make build-grafana
make build-prometheus
make build-blackbox
make build-loki
make build-alloy
```

There are also `run-*` and `remove-*` targets for each image.

## CI/CD

The `.github/workflows/deploy.yaml` workflow runs whenever a tag matching `*.*.*` is pushed.

Pipeline:

1. Builds and pushes images to GHCR:
   - `ghcr.io/pausegarra/grafana:<tag>`
   - `ghcr.io/pausegarra/prometheus:<tag>`
   - `ghcr.io/pausegarra/blackbox-exporter:<tag>`
   - `ghcr.io/pausegarra/loki:<tag>`
   - `ghcr.io/pausegarra/alloy:<tag>`
2. Runs `docker pull` on the remote server.
3. Runs `docker compose up -d --force-recreate` by piping `compose.yaml` over `stdin`.

Required GitHub Actions secrets:

- `SSH_PRIVATE_KEY`
- `SSH_PORT`
- `SSH_USERNAME`
- `SSH_HOST`
- `EMAIL_USERNAME`
- `EMAIL_PASSWORD`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_CLIENT_SECRET`

## Logs via OTLP

Projects should send logs to Alloy. The current pipeline promotes these attributes to Loki labels:

- `service.name`
- `service.namespace`
- `deployment.environment.name`
- `level`
- `logger`

For them to show up as filterable labels in Grafana, services must include these attributes in their OTLP telemetry.
