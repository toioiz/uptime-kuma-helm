# Uptime Kuma Helm Chart

A Helm chart for deploying [Uptime Kuma](https://github.com/louislam/uptime-kuma) - a self-hosted monitoring tool like "Uptime Robot".

## Features

- Support for both SQLite (default) and MariaDB/MySQL databases
- Configurable persistence with PersistentVolumeClaims
- Ingress support with customizable annotations
- Resource management and autoscaling
- Health checks (liveness and readiness probes)
- Security context configuration
- ServiceAccount support
- Comprehensive configuration options

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner support in the underlying infrastructure (if persistence is enabled)

## Installing the Chart

```bash
# Add your repository (if applicable)
# helm repo add my-repo https://...

# Install with default values (SQLite)
helm install uptime-kuma ./uptime-kuma

# Install with custom values
helm install uptime-kuma ./uptime-kuma -f custom-values.yaml

# Install with MariaDB
helm install uptime-kuma ./uptime-kuma \
  --set config.databaseType=mariadb \
  --set config.mariadb.enabled=true \
  --set config.mariadb.host=mariadb.default.svc.cluster.local \
  --set config.mariadb.password=your-secure-password
```

## Uninstalling the Chart

```bash
helm uninstall uptime-kuma
```

## Configuration

### Database Options

#### SQLite (Default)

```yaml
config:
  databaseType: sqlite
  sqlite:
    path: /app/data/kuma.db
```

#### MariaDB/MySQL

```yaml
config:
  databaseType: mariadb
  mariadb:
    enabled: true
    host: mariadb.default.svc.cluster.local
    port: 3306
    database: uptime_kuma
    username: uptime_kuma
    password: your-secure-password
    # Or use existing secret
    existingSecret: mariadb-secret
    existingSecretPasswordKey: password
    sslEnabled: false
    charset: utf8mb4
```

### Server Configuration

```yaml
config:
  server:
    port: 3001
    host: "0.0.0.0"
    baseUrl: "https://uptime.example.com"
```

### Persistence

```yaml
persistence:
  enabled: true
  storageClass: "standard"
  accessMode: ReadWriteOnce
  size: 4Gi
  # Use existing claim
  # existingClaim: my-existing-pvc
```

### Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
  hosts:
    - host: uptime.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: uptime-kuma-tls
      hosts:
        - uptime.example.com
```

### Resources

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Additional Environment Variables

```yaml
config:
  extraEnv:
    - name: TZ
      value: "America/New_York"
    - name: CUSTOM_VAR
      value: "custom-value"
  
  extraEnvFrom:
    - secretRef:
        name: uptime-kuma-secrets
    - configMapRef:
        name: uptime-kuma-config
```

## Common Configuration Examples

### Production Setup with MariaDB and Ingress

```yaml
replicaCount: 1

image:
  tag: "2.0.2"

config:
  databaseType: mariadb
  mariadb:
    enabled: true
    host: mariadb.database.svc.cluster.local
    port: 3306
    database: uptime_kuma
    username: uptime_kuma
    existingSecret: mariadb-credentials
    existingSecretPasswordKey: password
    sslEnabled: true
  
  server:
    baseUrl: "https://uptime.example.com"

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 10Gi

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
  hosts:
    - host: uptime.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: uptime-kuma-tls
      hosts:
        - uptime.example.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Simple Development Setup

```yaml
config:
  databaseType: sqlite

persistence:
  enabled: true
  size: 2Gi

service:
  type: NodePort

resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `louislam/uptime-kuma` |
| `image.tag` | Image tag | `2.0.2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `config.databaseType` | Database type (sqlite or mariadb) | `sqlite` |
| `config.server.port` | Server port | `3001` |
| `config.server.host` | Server host | `0.0.0.0` |
| `config.server.baseUrl` | Base URL for the application | `""` |
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.size` | PVC size | `4Gi` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `3001` |
| `ingress.enabled` | Enable ingress | `false` |
| `resources` | Resource limits and requests | `{}` |

For a complete list of parameters, see the `values.yaml` file.

## Backup and Restore

### SQLite Database

```bash
# Backup
kubectl cp <namespace>/<pod-name>:/app/data/kuma.db ./kuma-backup.db

# Restore
kubectl cp ./kuma-backup.db <namespace>/<pod-name>:/app/data/kuma.db
```

### MariaDB Database

Use standard MariaDB backup tools like `mysqldump`:

```bash
kubectl exec -it <mariadb-pod> -- mysqldump -u uptime_kuma -p uptime_kuma > backup.sql
```

## Troubleshooting

### Pod is not starting

Check pod logs:
```bash
kubectl logs -f <pod-name>
```

### Database connection issues

Verify database credentials and connectivity:
```bash
kubectl exec -it <pod-name> -- env | grep UPTIME_KUMA_DB
```

### Persistence issues

Check PVC status:
```bash
kubectl get pvc
kubectl describe pvc <pvc-name>
```

## License

This Helm chart is provided as-is. Uptime Kuma is licensed under the MIT License.

## Support

- Uptime Kuma Documentation: https://github.com/louislam/uptime-kuma
