# uptime-kuma Helm Chart

Production-ready Helm chart for [Uptime Kuma](https://github.com/louislam/uptime-kuma) using
[Docker Hardened Images](https://dhi.io) (`dhi.io`) for both the application and MySQL backend.

## Key features

- **`dhi.io/uptime-kuma:2.1.3`** — zero-CVE, signed, minimal runtime image
- **`dhi.io/mysql:8.4`** — hardened MySQL backend, deployed as a StatefulSet
- MySQL `init-container` waits for the database to be healthy before Uptime Kuma starts
- All passwords resolved from Kubernetes Secrets; supports `existingSecret` for external secret managers
- Configurable NetworkPolicy (Uptime Kuma ↔ MySQL only, plus DNS + external HTTP/S)
- Optional `dhi.io/mysqld-exporter` sidecar + Prometheus `ServiceMonitor`
- `helm.sh/resource-policy: keep` on PVCs and Secrets to prevent accidental data loss
- `Recreate` deployment strategy (Uptime Kuma is not horizontally scalable)
- Pod Disruption Budgets for both app and MySQL
- Full security context: non-root, `allowPrivilegeEscalation: false`, dropped capabilities

## Prerequisites

| Tool | Version |
|------|---------|
| Kubernetes | ≥ 1.26 |
| Helm | ≥ 3.10 |
| Docker account | Required to pull from `dhi.io` |

### dhi.io authentication

```bash
docker login dhi.io

kubectl create secret docker-registry dhi-registry-secret \
  --docker-server=dhi.io \
  --docker-username=<your-dockerhub-id> \
  --docker-password=<your-pat> \
  -n monitoring
```

## Quick start

```bash
helm upgrade --install uptime-kuma ./charts/uptime-kuma \
  --namespace monitoring --create-namespace \
  --set mysql.auth.rootPassword=changeme \
  --set mysql.auth.password=changeme \
  --set imagePullSecrets[0].name=dhi-registry-secret
```

## Production deployment

```bash
helm upgrade --install uptime-kuma ./charts/uptime-kuma \
  -f values.production.yaml \
  --namespace monitoring --create-namespace
```

See [`values.production.yaml`](./values.production.yaml) for a fully annotated production example.

## Using an external secret

Create a Secret with the required keys, then reference it:

```yaml
# Secret must contain: mysql-root-password, mysql-password
apiVersion: v1
kind: Secret
metadata:
  name: uptime-kuma-mysql-credentials
  namespace: monitoring
type: Opaque
stringData:
  mysql-root-password: "s3cr3t-root"
  mysql-password: "s3cr3t-app"
```

```bash
helm upgrade --install uptime-kuma ./charts/uptime-kuma \
  --set mysql.auth.existingSecret=uptime-kuma-mysql-credentials \
  --set imagePullSecrets[0].name=dhi-registry-secret \
  -n monitoring
```

## Using an external MySQL / MariaDB

```bash
helm upgrade --install uptime-kuma ./charts/uptime-kuma \
  --set mysql.enabled=false \
  --set externalDatabase.host=my-mysql.example.com \
  --set externalDatabase.password=changeme \
  -n monitoring
```

## Key values reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `dhi.io/uptime-kuma` | Uptime Kuma image |
| `image.tag` | `2.1.3` | Image tag (pin this!) |
| `mysql.enabled` | `true` | Deploy bundled MySQL |
| `mysql.image.repository` | `dhi.io/mysql` | MySQL image |
| `mysql.image.tag` | `8.4` | MySQL version |
| `mysql.auth.rootPassword` | `""` | **Required** root password |
| `mysql.auth.password` | `""` | **Required** app password |
| `mysql.auth.existingSecret` | `""` | Pre-existing Secret name |
| `mysql.persistence.size` | `8Gi` | MySQL PVC size |
| `persistence.size` | `5Gi` | Uptime Kuma data PVC size |
| `ingress.enabled` | `false` | Create Ingress resource |
| `networkPolicy.enabled` | `false` | Enable NetworkPolicies |
| `metrics.enabled` | `false` | mysqld-exporter sidecar |
| `metrics.serviceMonitor.enabled` | `false` | Prometheus ServiceMonitor |

## Upgrading

```bash
helm upgrade uptime-kuma ./charts/uptime-kuma -n monitoring
```

> PVCs and Secrets are annotated with `helm.sh/resource-policy: keep` so they survive `helm uninstall`.

## Uninstall

```bash
helm uninstall uptime-kuma -n monitoring
# Manually delete PVCs if no longer needed:
kubectl delete pvc -l app.kubernetes.io/instance=uptime-kuma -n monitoring
```
