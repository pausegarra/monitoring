# monitoring

Monitoring stack for K3s based on Prometheus, Grafana, Loki, Alloy, and Blackbox Exporter.

## What it includes

- `Prometheus` scraping application metrics, blackbox HTTP healthchecks, and K3s cAdvisor metrics from kubelet.
- `Grafana` with provisioned dashboards, alerting, and datasources mounted from Kubernetes `ConfigMap`s.
- `Loki` for log storage with persistent volume.
- `Alloy` running as a `DaemonSet` to collect Kubernetes pod logs and forward them to Loki.
- `Blackbox Exporter` for external HTTP healthchecks.

## Structure

- `monitoring-namespace.yaml`: namespace for the monitoring stack.
- `prometheus/`: `Deployment`, `Service`, `ConfigMap`, and RBAC for Prometheus.
- `grafana/`: `Deployment`, `Service`, `PVC`, provisioned `ConfigMap`s, and Grafana source files.
- `loki/`: `Deployment`, `Service`, `PVC`, and `ConfigMap` for Loki.
- `alloy/`: `DaemonSet`, RBAC, `ServiceAccount`, and `ConfigMap` for log collection in Kubernetes.
- `blackbox/`: `Deployment`, `Service`, and `ConfigMap` for blackbox checks.
- `config/`: legacy Docker-era source configs kept as references.
- `compose.yaml`: older Docker-based production stack kept in the repo for reference.

## Kubernetes

The current deployment target is K3s.

Apply the namespace first:

```bash
kubectl apply -f monitoring-namespace.yaml
```

Then apply the components:

```bash
kubectl apply -f loki/configmap.yaml
kubectl apply -f loki/pvc.yaml
kubectl apply -f loki/deployment.yaml
kubectl apply -f loki/service.yaml

kubectl apply -f blackbox/configmap.yaml
kubectl apply -f blackbox/deployment.yaml
kubectl apply -f blackbox/service.yaml

kubectl apply -f alloy/serviceaccount.yaml
kubectl apply -f alloy/rbac.yaml
kubectl apply -f alloy/configmap.yaml
kubectl apply -f alloy/daemonset.yaml

kubectl apply -f prometheus/rbac.yaml
kubectl apply -f prometheus/configmap.yaml
kubectl apply -f prometheus/deployment.yaml
kubectl apply -f prometheus/service.yaml

kubectl apply -f grafana/configmap-grafana-ini.yaml
kubectl apply -f grafana/configmap-grafana-datasources.yaml
kubectl apply -f grafana/configmap-grafana-alerting.yaml
kubectl apply -f grafana/configmap-grafana-dashboards.yaml
kubectl apply -f grafana/configmap-grafana-dashboards-2.yaml
kubectl apply -f grafana/pvc.yaml
kubectl apply -f grafana/deployment.yaml
kubectl apply -f grafana/service.yaml
```

Grafana expects an existing secret named `grafana-secret` in namespace `monitoring` with these keys:

- `EMAIL_USERNAME`
- `EMAIL_PASSWORD`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_CLIENT_SECRET`

## Grafana Provisioning

Grafana provisions:

- Prometheus as the default datasource
- Loki as the logs datasource
- dashboards from `grafana/dashboards/`
- alerting resources from `grafana/alerting/`
- configuration from `grafana/config/grafana.ini`

Dashboard manifests are split across two `ConfigMap`s to stay below Kubernetes object size limits:

- `grafana/configmap-grafana-dashboards.yaml`
- `grafana/configmap-grafana-dashboards-2.yaml`

## Logs

In Kubernetes, Alloy collects logs from pods via Kubernetes discovery and sends them to Loki.

Projects can still send OTLP logs separately if needed, but the current K3s deployment is focused on Kubernetes pod log collection rather than the older Docker OTLP pipeline.
