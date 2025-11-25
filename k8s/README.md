# Kubernetes Configuration - e-Commerce Microservices

Este directorio contiene toda la configuración necesaria para desplegar los microservicios de e-Commerce en Kubernetes.

## 📁 Estructura

```
k8s/
├── namespaces/              # Definiciones de namespaces (dev, qa, prod)
├── infrastructure/          # NetworkPolicies y configuración de red
├── security/                # RBAC, Pod Security, PDB
├── persistence/             # Storage, PVC, StatefulSets
├── monitoring/              # Prometheus, Grafana, Jaeger
├── logging/                 # ELK Stack (Elasticsearch, Kibana, Logstash)
├── helm/                    # Helm Charts para despliegue
├── load-testing/            # JMeter, Locust scripts
└── cicd/                    # (Futuro) GitOps, ArgoCD
```

## 🚀 Quick Start

### Opción 1: Script Automatizado (Recomendado)

```bash
cd ..  # Ir al directorio raíz del proyecto
chmod +x k8s-deploy.sh
./k8s-deploy.sh dev
```

Este script:
1. Verifica requisitos
2. Crea namespaces
3. Instala infraestructura (Ingress, cert-manager)
4. Despliega todos los microservicios
5. Verifica estado

### Opción 2: Manual Step-by-Step

```bash
# 1. Crear namespaces
kubectl apply -f namespaces/namespaces.yaml

# 2. Infraestructura
kubectl apply -f infrastructure/network-policies.yaml
kubectl apply -f security/rbac.yaml
kubectl apply -f security/pod-security.yaml

# 3. Almacenamiento
kubectl apply -f persistence/mysql-storage.yaml

# 4. Monitoreo
kubectl apply -f monitoring/prometheus.yaml
kubectl apply -f monitoring/grafana.yaml
kubectl apply -f monitoring/jaeger.yaml

# 5. Logging
kubectl apply -f logging/elk-stack.yaml

# 6. Microservicios (con Helm)
helm install ecommerce ./helm/ecommerce-microservices \
  -n ecommerce-dev \
  -f ./helm/ecommerce-microservices/values/dev.yaml
```

## 📋 Archivos Principales

### namespaces/
- **namespaces.yaml**: Define 4 namespaces con labels de ambiente

### infrastructure/
- **network-policies.yaml**: Políticas de comunicación entre servicios
  - Restricción por servicio
  - Whitelist explícito
  - API Gateway como punto de entrada único

### security/
- **rbac.yaml**: ServiceAccounts, Roles, RoleBindings
  - Permisos mínimos por servicio
  - ClusterRoles para recursos compartidos
  
- **pod-security.yaml**: Pod Security Standards, PDB
  - Baseline (dev) / Restricted (qa, prod)
  - Non-root containers
  - Read-only filesystems

### persistence/
- **mysql-storage.yaml**: 
  - StorageClass (host-path para dev/minikube)
  - PVC por ambiente (10Gi dev, 20Gi qa, 50Gi prod)
  - StatefulSet MySQL con backup-ready structure

### monitoring/
- **prometheus.yaml**:
  - Deployment con 2 replicas
  - ConfigMap con scrape targets
  - RBAC para acceso a API server
  
- **grafana.yaml**:
  - Deployment con persistencia
  - Provisioning automático de datasources
  - Service LoadBalancer
  - Ingress para acceso HTTPS

- **jaeger.yaml**:
  - All-in-one deployment
  - Puertos para Zipkin compatibility
  - UI en puerto 16686

### logging/
- **elk-stack.yaml**:
  - Elasticsearch StatefulSet (20Gi)
  - Kibana para visualización
  - Logstash para procesamiento
  - Ingress para acceso web

### helm/ecommerce-microservices/
- **Chart.yaml**: Metadatos del Helm chart
- **values.yaml**: Valores por defecto
- **values/**: Valores por ambiente (dev.yaml, qa.yaml, prod.yaml)
- **templates/**: Templates de Kubernetes
  - _helpers.tpl: Funciones helper
  - deployment.yaml: Deployments para todos los servicios
  - service.yaml: Services
  - configmap.yaml: ConfigMaps
  - secret.yaml: Secrets
  - hpa.yaml: Horizontal Pod Autoscaler
  - ingress.yaml: Ingress
  - serviceaccount.yaml: ServiceAccounts

### load-testing/
- **locustfile.py**: Script de Locust con escenarios de carga
- **locust-deployment.yaml**: Deployment distribuido de Locust en K8s
- **jmeter-config.yaml**: Configuración JMeter como ConfigMap
- **run-load-test.sh**: Script shell para ejecutar tests

## 🔧 Configuración por Ambiente

### Dev
- Namespace: `ecommerce-dev`
- Replicas: 1-2 por servicio
- Storage: 10Gi
- Security: Baseline
- Autoscaling: 1-3 replicas

### QA
- Namespace: `ecommerce-qa`
- Replicas: 2 por servicio
- Storage: 20Gi
- Security: Restricted
- Autoscaling: 2-5 replicas

### Prod
- Namespace: `ecommerce-prod`
- Replicas: 3 por servicio
- Storage: 50Gi
- Security: Restricted
- Autoscaling: 3-20 replicas
- TLS: Let's Encrypt obligatorio
- Secrets: Sealed Secrets recomendado

## 📊 Configuración de Helm

### Valores Predeterminados (values.yaml)

```yaml
replicaCount: 2
image:
  registry: docker.io
  repository: selimhorri
  tag: "0.1.0"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### Customización

```bash
# Override valores individuales
helm install ecommerce ./helm/ecommerce-microservices \
  -n ecommerce-dev \
  -f values/dev.yaml \
  --set image.tag=v0.2.0 \
  --set replicaCount=5

# Usar valores de archivo
helm install ecommerce ./helm/ecommerce-microservices \
  -n ecommerce-prod \
  -f values/prod.yaml \
  -f custom-overrides.yaml
```

## 🌐 Acceso a Servicios

### Servicios Internos (ClusterIP)
```bash
kubectl get svc -n ecommerce-dev

# Usar DNS interno:
http://api-gateway.ecommerce-dev.svc.cluster.local:8080
http://user-service.ecommerce-dev.svc.cluster.local:8700
```

### Servicios Públicos (Ingress)
```
https://api.ecommerce.local              → api-gateway:8080
https://eureka.ecommerce.local           → service-discovery:8761
https://config.ecommerce.local           → cloud-config:9296
https://grafana.ecommerce.local          → grafana:3000 (admin/admin123)
https://prometheus.ecommerce.local       → prometheus:9090
https://jaeger.ecommerce.local           → jaeger:16686
https://kibana.ecommerce.local           → kibana:5601
```

## 🔐 Secretos y Configuración

### ConfigMap
Automáticamente inyectado en todos los pods:

```
SPRING_PROFILES_ACTIVE: kubernetes
EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://service-discovery:8761/eureka
SPRING_CLOUD_CONFIG_URI: http://cloud-config:9296
ZIPKIN_BASEURL: http://zipkin:9411
```

### Secrets
Base64 encoded en Kubernetes nativamente:

```bash
# Crear secret
kubectl create secret generic mysql-credentials \
  --from-literal=username=ecommerce \
  --from-literal=password=secure-pass \
  -n ecommerce-dev

# Ver (encoded)
kubectl get secret -n ecommerce-dev mysql-credentials -o yaml

# Decodificar
kubectl get secret -n ecommerce-dev mysql-credentials \
  -o jsonpath='{.data.password}' | base64 -d
```

## 📈 Monitoreo

### Prometheus Targets
Automáticamente descubre pods con:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/actuator/prometheus"
```

### Métricas Disponibles
```
Prometheus query examples:
- sum(rate(http_server_requests_seconds_count[5m])) by (uri)
- rate(jvm_gc_pause_seconds[5m])
- container_cpu_usage_seconds_total
- container_memory_usage_bytes
```

## 🔄 Despliegue y Updates

### Despliegue Inicial
```bash
./k8s-deploy.sh dev          # Full deployment
./k8s-deploy.sh dev skip-infra  # Solo servicios
```

### Update de Imagen
```bash
# Método 1: kubectl
kubectl set image deployment/api-gateway \
  api-gateway=selimhorri/api-gateway:v0.2.0 \
  -n ecommerce-dev

# Método 2: Helm
helm upgrade ecommerce ./helm/ecommerce-microservices \
  -n ecommerce-dev \
  --set image.tag=v0.2.0 \
  --wait
```

### Rollback
```bash
# kubectl
kubectl rollout undo deployment/api-gateway -n ecommerce-dev

# Helm
helm rollback ecommerce 1 -n ecommerce-dev
```

## 🧪 Pruebas de Carga

```bash
# Con Locust (local)
locust -f load-testing/locustfile.py \
  --host=http://api-gateway.ecommerce-dev.svc.cluster.local:8080 \
  --users=100 --spawn-rate=10 --run-time=5m

# Distribuido en Kubernetes
kubectl apply -f load-testing/locust-deployment.yaml
# Acceder a http://locust.ecommerce.local
```

## 📚 Documentación Relacionada

- **../KUBERNETES_ARCHITECTURE.md** - Arquitectura completa
- **../OPERATIONS_GUIDE.md** - Guía de operaciones
- **../SECURITY_GUIDE.md** - Guía de seguridad
- **../K8S_IMPLEMENTATION_SUMMARY.md** - Resumen de implementación

## 🛠️ Troubleshooting

```bash
# Ver estado general
kubectl get all -n ecommerce-dev

# Logs de un servicio
kubectl logs -n ecommerce-dev -l app=api-gateway -f

# Describir problemas
kubectl describe pod -n ecommerce-dev <pod-name>

# Ejecutar comando en pod
kubectl exec -it -n ecommerce-dev <pod-name> -- bash

# Port-forward para debug
kubectl port-forward -n ecommerce-dev <pod-name> 8080:8080
```

## 🔗 Enlaces Útiles

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Spring Boot on Kubernetes](https://spring.io/projects/spring-cloud-kubernetes)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

---

**Para comenzar**: `cd .. && ./k8s-deploy.sh dev`

**Para comandos útiles**: `source k8s-commands.sh && help`
