# 📑 ÍNDICE COMPLETO Y REFERENCIAS

## 🎯 EMPEZAR AQUÍ

Si eres nuevo en este proyecto, lee estos archivos **EN ORDEN**:

1. **README.md** ← Descripción general del proyecto
2. **KUBERNETES_ARCHITECTURE.md** ← Diseño y componentes
3. **QUICK_START.sh** ← Guía rápida de setup
4. **OPERATIONS_GUIDE.md** ← Cómo operar el sistema
5. **SECURITY_GUIDE.md** ← Configuración de seguridad
6. **REQUIREMENTS_CHECKLIST.md** ← Validar requisitos cumplidos

---

## 📂 ESTRUCTURA DE DIRECTORIOS

### k8s/ - Todas las configuraciones Kubernetes

```
k8s/
├── README.md                              # 📖 Inicio aquí
├── namespaces/
│   └── namespaces.yaml                   # Namespaces: dev, qa, prod
├── infrastructure/
│   └── network-policies.yaml             # Políticas de red entre servicios
├── security/
│   ├── rbac.yaml                         # RBAC y ServiceAccounts
│   └── pod-security.yaml                 # Pod Security Standards + PDB
├── persistence/
│   └── mysql-storage.yaml                # StorageClass, PVC, MySQL StatefulSet
├── monitoring/
│   ├── prometheus.yaml                   # Prometheus + scrape configs
│   ├── grafana.yaml                      # Grafana + dashboards
│   └── jaeger.yaml                       # Jaeger distributed tracing
├── logging/
│   └── elk-stack.yaml                    # Elasticsearch, Logstash, Kibana
├── helm/
│   └── ecommerce-microservices/
│       ├── Chart.yaml                    # Chart metadata
│       ├── values.yaml                   # Default values
│       ├── values/
│       │   ├── dev.yaml                  # Development config
│       │   ├── qa.yaml                   # QA config
│       │   └── prod.yaml                 # Production config
│       └── templates/
│           ├── _helpers.tpl              # Template helpers
│           ├── configmap.yaml            # ConfigMap template
│           ├── secret.yaml               # Secret template
│           ├── serviceaccount.yaml       # ServiceAccount template
│           ├── deployment.yaml           # Deployment template
│           ├── service.yaml              # Service template
│           ├── hpa.yaml                  # HorizontalPodAutoscaler
│           └── ingress.yaml              # Ingress with TLS
├── load-testing/
│   ├── jmeter-config.yaml               # JMeter test plan
│   ├── locustfile.py                    # Locust test scenarios
│   ├── locust-deployment.yaml           # Locust in Kubernetes
│   └── run-load-test.sh                 # Load test execution script
└── cicd/                                 # CI/CD related configs
```

---

## 📄 ARCHIVOS PRINCIPALES

### Configuración Base

#### `k8s/namespaces/namespaces.yaml`
**Propósito**: Crear namespaces para ambiente separation
- **Namespaces**: ecommerce-dev, ecommerce-qa, ecommerce-prod, ecommerce-infrastructure
- **Deployment**: `kubectl apply -f k8s/namespaces/namespaces.yaml`
- **Líneas**: 50
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Namespace Management")

#### `k8s/helm/ecommerce-microservices/Chart.yaml`
**Propósito**: Metadata del Helm Chart
- **Versión Chart**: 0.1.0
- **Versión App**: 0.1.0
- **Líneas**: 15
- **Ver también**: `values.yaml`, `values/dev.yaml`, `values/qa.yaml`, `values/prod.yaml`

#### `k8s/helm/ecommerce-microservices/values.yaml`
**Propósito**: Default values para Helm chart
- **Contenido**: replicaCount, image registry, resource limits, HPA settings
- **Líneas**: 80+
- **Uso**: `helm install ecommerce -f values.yaml k8s/helm/ecommerce-microservices`
- **Ver también**: values/dev.yaml, values/qa.yaml, values/prod.yaml

### Kubernetes Manifests

#### `k8s/helm/ecommerce-microservices/templates/deployment.yaml`
**Propósito**: Deployment template para todos los microservicios
- **Características**:
  - Init containers para dependency ordering
  - Health checks (liveness, readiness, startup)
  - Environment variables desde ConfigMap/Secret
  - Resource requests y limits
  - Init container para esperar a Eureka y Cloud Config
- **Líneas**: 120+
- **Parámetros**: Templated via Helm values
- **Comando**: `helm template ecommerce k8s/helm/ecommerce-microservices | grep "kind: Deployment"`

#### `k8s/helm/ecommerce-microservices/templates/service.yaml`
**Propósito**: Service template (ClusterIP, NodePort, LoadBalancer)
- **Tipos soportados**: ClusterIP (default), NodePort, LoadBalancer
- **Puertos**: Dinamicamente configurados
- **Líneas**: 50+
- **Uso**: Comunicación inter-pod y external access

#### `k8s/helm/ecommerce-microservices/templates/configmap.yaml`
**Propósito**: ConfigMap para variables no-sensitivas
- **Contenido**: Spring Boot properties, URLs, feature flags
- **Líneas**: 60+
- **Sensibilidad**: NO sensitivo
- **Ver también**: secret.yaml (para datos sensibles)

#### `k8s/helm/ecommerce-microservices/templates/secret.yaml`
**Propósito**: Secret para credenciales y datos sensibles
- **Contenido**: Contraseñas BD, API keys, tokens
- **Encoding**: Base64 (Kubernetes default)
- **Líneas**: 50+
- **Nota**: En PROD usar Sealed Secrets o External Secrets
- **Ver también**: SECURITY_GUIDE.md (Sección "Secrets Management")

#### `k8s/helm/ecommerce-microservices/templates/serviceaccount.yaml`
**Propósito**: ServiceAccount y RBAC binding
- **Características**:
  - ServiceAccount per deployment
  - RoleBinding a ClusterRole compartido
  - Pods usan el SA para acceso a recursos
- **Líneas**: 40+
- **Política**: Least privilege

#### `k8s/helm/ecommerce-microservices/templates/hpa.yaml`
**Propósito**: Horizontal Pod Autoscaler
- **Métricas**:
  - CPU utilization: 70%
  - Memory utilization: 80%
- **Replicas**:
  - Dev: min=1, max=3
  - QA: min=2, max=5
  - Prod: min=3, max=20
- **Líneas**: 100+
- **Comportamiento**: Scale-up inmediato, scale-down con 300s delay

#### `k8s/helm/ecommerce-microservices/templates/ingress.yaml`
**Propósito**: Ingress para HTTP/HTTPS access
- **Características**:
  - TLS/HTTPS con Let's Encrypt
  - Path-based routing
  - Host-based routing
  - Rate limiting
  - Redirect HTTP → HTTPS
- **Líneas**: 80+
- **Controller**: NGINX Ingress Controller
- **Ver también**: Instalar cert-manager para auto-SSL

### Security & Networking

#### `k8s/infrastructure/network-policies.yaml`
**Propósito**: NetworkPolicies para aislamiento de servicios
- **Políticas** (8+):
  - API Gateway ingress (accept from external)
  - Service-to-service communication
  - Database access (MySQL)
  - Prometheus scraping
  - Elasticsearch access
  - Kibana access
  - Default deny (prod)
- **Líneas**: 200+
- **CNI Required**: Calico, Weave, o similar
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Network Policies")

#### `k8s/security/rbac.yaml`
**Propósito**: RBAC configuration
- **Contenido**:
  - ClusterRole "ecommerce-config-reader" (shared)
  - Roles por namespace
  - RoleBindings con ServiceAccounts
  - Permisos: get/list/watch ConfigMaps, Secrets, Services
  - Acceso a endpoints para logging/metrics
- **Líneas**: 150+
- **Política**: Least privilege
- **Ver también**: SECURITY_GUIDE.md (Sección "RBAC")

#### `k8s/security/pod-security.yaml`
**Propósito**: Pod Security Standards enforcement
- **Configuración**:
  - Baseline para dev
  - Restricted para qa/prod
  - Prohibit privileged containers
  - Require non-root users
  - Read-only root filesystem donde posible
- **Incluye**: Pod Disruption Budgets (PDB)
- **Líneas**: 50+
- **Ver también**: SECURITY_GUIDE.md (Sección "Pod Security Standards")

### Storage & Persistence

#### `k8s/persistence/mysql-storage.yaml`
**Propósito**: Storage configuration para MySQL
- **Componentes**:
  - StorageClass "ecommerce-mysql-storage"
  - PersistentVolume (opcional, para static provisioning)
  - PersistentVolumeClaim por ambiente
  - StatefulSet MySQL 8.0
  - Headless Service para replication
  - Secret con credentials
- **Tamaños**:
  - Dev: 10Gi
  - QA: 20Gi
  - Prod: 50Gi
- **Líneas**: 200+
- **Replicación**: Master-slave setup
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Database Management")

### Monitoring & Observability

#### `k8s/monitoring/prometheus.yaml`
**Propósito**: Prometheus deployment
- **Contenido**:
  - Prometheus Deployment (2 replicas)
  - ServiceMonitor CRD
  - Scrape configs:
    - Spring Boot Actuator (/actuator/prometheus)
    - Kubernetes API Server
    - Node exporter
    - Custom metrics
  - ConfigMap con prometheus.yml
  - Service ClusterIP en puerto 9090
  - Persistent storage (20Gi)
  - Retention: 30 days
- **Líneas**: 200+
- **Queries**: Ver ejemplos en OPERATIONS_GUIDE.md
- **Ver también**: grafana.yaml para visualization

#### `k8s/monitoring/grafana.yaml`
**Propósito**: Grafana deployment
- **Características**:
  - Grafana Deployment (2 replicas)
  - Prometheus datasource pre-configured
  - Grafana provisioning (dashboards + datasources)
  - Admin credentials via Secret
  - Service ClusterIP en puerto 3000
  - Ingress para acceso web
  - StorageClass para persistent data
- **Dashboards Pre-creados**:
  - Cluster Health
  - Microservices Overview
  - JVM Metrics
  - Database Metrics
- **Líneas**: 250+
- **Default User**: admin (ver secret para password)
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Grafana Setup")

#### `k8s/monitoring/jaeger.yaml`
**Propósito**: Jaeger distributed tracing
- **Setup**:
  - Jaeger All-in-One Deployment
  - Collector en puerto 6831 (UDP, Thrift)
  - Query UI en puerto 16686
  - Elasticsearch backend (opcional)
  - Zipkin compatibility
- **Integración**: Spring Cloud Sleuth
- **Sampling**: 10% (configurable)
- **Líneas**: 150+
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Jaeger Setup")

#### `k8s/logging/elk-stack.yaml`
**Propósito**: ELK Stack (Elasticsearch, Kibana, Logstash)
- **Componentes**:
  - Elasticsearch StatefulSet (3 nodes para HA)
  - Kibana Deployment
  - Logstash Deployment
  - PersistentVolume para Elasticsearch
  - Secrets para credentials
  - Index lifecycle management
  - Services para comunicación
- **Almacenamiento**: 20Gi por Elasticsearch node
- **Kibana UI**: Puerto 5601
- **Líneas**: 300+
- **Ver también**: OPERATIONS_GUIDE.md (Sección "Logging Setup")

### Load Testing

#### `k8s/load-testing/jmeter-config.yaml`
**Propósito**: JMeter test plan (ConfigMap)
- **Escenarios**:
  - Thread Groups para diferentes tipos de carga
  - HTTP Samplers para endpoints
  - Assertions para validación
  - Listeners para reporte
- **Líneas**: 200+
- **Ejecución**: Via `run-load-test.sh`
- **Ver también**: locustfile.py (alternativa)

#### `k8s/load-testing/locustfile.py`
**Propósito**: Locust test scenarios
- **Características**:
  - HttpUser classes
  - @task decorators para escenarios
  - Weight specification para probabilidades
  - Custom metrics
  - 8 escenarios de negocio:
    1. Browse Products (3x weight)
    2. List Products (2x weight)
    3. Get User Profile (1x weight)
    4. Add to Favorites (2x weight)
    5. Create Order (1x weight)
    6. Get Order
    7. Process Payment (1x weight)
    8. Check Health
- **Líneas**: 250+
- **Python Version**: 3.8+
- **Ejecución**: `python -m locust -f locustfile.py --host=http://api-gateway:8080`

#### `k8s/load-testing/locust-deployment.yaml`
**Propósito**: Locust distributed setup en Kubernetes
- **Componentes**:
  - ConfigMap con locustfile.py
  - Locust Master Deployment
  - Locust Worker StatefulSet (escalable)
  - Services para master-worker communication
  - Web UI Ingress
- **Líneas**: 150+
- **Escalado**: Aumentar replicas de workers para más carga
- **Ver también**: run-load-test.sh

#### `k8s/load-testing/run-load-test.sh`
**Propósito**: Script para ejecutar tests
- **Parámetros**:
  - Environment (dev/qa/prod)
  - Num users
  - Ramp-up time
  - Duration
- **Líneas**: 200+
- **Ejemplo**: `bash run-load-test.sh prod 100 10 5m`
- **Output**: Archivo de reporte HTML/JSON

### CI/CD Pipeline

#### `.github/workflows/build-deploy.yaml`
**Propósito**: GitHub Actions CI/CD pipeline
- **Etapas**:
  1. Build: Maven clean package + tests
  2. Security: Trivy vulnerability scanning
  3. Docker: Build & push images (paralelo)
  4. Deploy Dev: Automático desde develop branch
  5. Deploy Prod: Manual approval en master branch
- **Triggers**:
  - Push a develop/main
  - Pull requests
  - Manual workflow dispatch
- **Líneas**: 300+
- **Docker Registry**: Docker Hub (selimhorri/*)
- **Secrets requeridos**:
  - DOCKER_USERNAME
  - DOCKER_PASSWORD
  - KUBE_CONFIG_DEV
  - KUBE_CONFIG_PROD
- **Ver también**: OPERATIONS_GUIDE.md (Sección "CI/CD Setup")

---

## 📖 ARCHIVOS DE DOCUMENTACIÓN

### `KUBERNETES_ARCHITECTURE.md`
**Contenido**: Diseño completo de la arquitectura
- **Secciones**:
  - Visión general
  - Componentes arquitectónicos
  - Diagramas de flujo
  - Patrones de diseño
  - Decisiones de diseño
  - Explicación por servicio
  - Escalabilidad y HA
  - Security posture
- **Palabras**: 2000+
- **Audiencia**: Arquitectos, DevOps engineers
- **Leer después de**: README.md

### `OPERATIONS_GUIDE.md`
**Contenido**: Cómo operar el sistema
- **Secciones**:
  - Prerequisites
  - Setup paso a paso
  - Deployment procedures
  - Troubleshooting (30+ problemas comunes)
  - Monitoring setup
  - Database management
  - Backup & restore
  - Performance tuning
  - 50+ comandos prácticos
  - Canary & Blue-Green deployments
  - Disaster recovery
- **Palabras**: 2500+
- **Audiencia**: DevOps engineers, SREs
- **Leer después de**: KUBERNETES_ARCHITECTURE.md

### `SECURITY_GUIDE.md`
**Contenido**: Configuración de seguridad
- **Secciones**:
  - Secrets management (Kubernetes, Sealed, External)
  - RBAC detallado
  - NetworkPolicies
  - Pod Security Standards
  - Encriptación en tránsito (TLS)
  - Encriptación en reposo
  - Vulnerability scanning (Trivy, Grype, Snyk)
  - Image security
  - Supply chain security
  - Mejores prácticas
  - Checklist de seguridad
- **Palabras**: 1500+
- **Audiencia**: Security engineers, DevOps
- **Leer después de**: OPERATIONS_GUIDE.md

### `K8S_IMPLEMENTATION_SUMMARY.md`
**Contenido**: Resumen ejecutivo
- **Secciones**:
  - Overview
  - Archivos creados
  - Requisitos cumplidos
  - Líneas de código por componente
  - URLs de acceso
  - Quick start guide
  - Próximos pasos
- **Palabras**: 1000+
- **Audiencia**: Managers, stakeholders
- **Leer después de**: KUBERNETES_ARCHITECTURE.md

### `REQUIREMENTS_CHECKLIST.md`
**Contenido**: Checklist de requisitos cumplidos
- **Secciones por requisito**:
  - Descripción
  - Checklist de implementación
  - Líneas de código
  - Archivos relacionados
  - Estado (✅ Completado)
- **7 requisitos**: 100% completados
- **Total líneas**: 5675+
- **Audiencia**: Project managers, stakeholders
- **Leer para**: Validar completitud

### `QUICK_START.sh`
**Contenido**: Guía rápida de navegación (este archivo)
- **Secciones**:
  - Estructura de directorios
  - Comandos rápidos
  - Servicios y puertos
  - Credenciales
  - Troubleshooting
  - Documentación references
  - Próximos pasos
  - Checklist final
- **Líneas**: 500+
- **Audiencia**: Todos
- **Leer primero**: Este archivo

### `IMPLEMENTATION_COMPLETE.md`
**Contenido**: Resumen final del proyecto
- **Secciones**:
  - Archivos y carpetas creados
  - 10 microservicios
  - CI/CD pipeline
  - Documentación
  - Requisitos cumplidos
  - Features adicionales
  - Cómo usar
  - Estadísticas
  - Próximos pasos
- **Audiencia**: Todos
- **Leer para**: Entender qué se ha completado

### `k8s/README.md`
**Contenido**: Estructura del directorio k8s
- **Secciones**:
  - Descripción de cada subdirectorio
  - Archivos clave
  - Cómo usarlos
  - Relaciones entre componentes
- **Audiencia**: Desarrolladores, DevOps
- **Leer para**: Navegar el directorio k8s

---

## 🔧 ARCHIVOS DE SCRIPTS

### `k8s-deploy.sh`
**Propósito**: Desplegar a dev/qa/prod
- **Uso**: `./k8s-deploy.sh [dev|qa|prod]`
- **Funciones**:
  - Crear namespaces
  - Validar prerequisites
  - Aplicar ConfigMaps/Secrets
  - Deploy con Helm
  - Health checks
  - Status reporting
- **Líneas**: 500+
- **Error handling**: Completo
- **Color output**: Sí
- **Documentación**: Ver dentro del script

### `k8s-commands.sh`
**Propósito**: Funciones útiles para operaciones
- **Funciones** (60+):
  - help: ver todas las funciones
  - deploy-all: desplegar todo
  - status-all: estado general
  - logs-all: todos los logs
  - scale-deployment: escalar manualmente
  - port-forward-all: forward a local
  - health-check: verificar health
  - get-secrets: obtener credenciales
  - backup-db: backup de MySQL
  - restore-db: restaurar MySQL
  - load-test: ejecutar tests
  - ...y 50+ más
- **Líneas**: 500+
- **Uso**: `source k8s-commands.sh; help`
- **Documentación**: Ver dentro del script

### `run-load-test.sh`
**Propósito**: Ejecutar pruebas de carga
- **Uso**: `bash run-load-test.sh prod 100 10 5m`
- **Parámetros**:
  - Ambiente (dev/qa/prod)
  - Número de usuarios
  - Ramp-up time (segundos)
  - Duración total
- **Líneas**: 200+
- **Output**: Reporte de resultados
- **Herramientas**: Locust
- **Ver también**: locustfile.py

---

## 🎯 BÚSQUEDA RÁPIDA

### Por Componente

#### Microservicios
- **Configuración general**: `k8s/helm/ecommerce-microservices/templates/deployment.yaml`
- **Service discovery**: `k8s/namespaces/namespaces.yaml` + Eureka en port 8761
- **Config server**: Cloud Config en port 9296

#### API Gateway
- **Deployment**: `k8s/helm/ecommerce-microservices/templates/deployment.yaml`
- **Service**: `k8s/helm/ecommerce-microservices/templates/service.yaml`
- **Ingress**: `k8s/helm/ecommerce-microservices/templates/ingress.yaml`
- **Network policy**: `k8s/infrastructure/network-policies.yaml` (API Gateway ingress)

#### Base de Datos
- **StorageClass**: `k8s/persistence/mysql-storage.yaml`
- **StatefulSet**: `k8s/persistence/mysql-storage.yaml`
- **Backup**: `k8s-commands.sh` (función `backup_db`)
- **Restore**: `k8s-commands.sh` (función `restore_db`)

#### Monitoreo
- **Prometheus**: `k8s/monitoring/prometheus.yaml`
- **Grafana**: `k8s/monitoring/grafana.yaml`
- **Jaeger**: `k8s/monitoring/jaeger.yaml`
- **Comandos**: `k8s-commands.sh` (funciones `prometheus_*`, `grafana_*`, `jaeger_*`)

#### Logging
- **ELK Stack**: `k8s/logging/elk-stack.yaml`
- **Comandos**: `k8s-commands.sh` (funciones `kibana_*`, `elasticsearch_*`)

#### Load Testing
- **Locust**: `k8s/load-testing/locustfile.py` + `k8s/load-testing/locust-deployment.yaml`
- **JMeter**: `k8s/load-testing/jmeter-config.yaml`
- **Ejecución**: `k8s/load-testing/run-load-test.sh`

#### Seguridad
- **RBAC**: `k8s/security/rbac.yaml`
- **Network policies**: `k8s/infrastructure/network-policies.yaml`
- **Pod security**: `k8s/security/pod-security.yaml`
- **Secrets**: `k8s/helm/ecommerce-microservices/templates/secret.yaml`
- **Documentación**: `SECURITY_GUIDE.md`

#### CI/CD
- **GitHub Actions**: `.github/workflows/build-deploy.yaml`
- **Helm charts**: `k8s/helm/ecommerce-microservices/`
- **Deployment script**: `k8s-deploy.sh`

### Por Tarea

#### "Necesito desplegar"
1. Lee: `QUICK_START.sh` (Sección "Comandos Rápidos")
2. Ejecuta: `./k8s-deploy.sh dev` (o qa/prod)
3. Verifica: `kubectl get pods -n ecommerce-dev`

#### "Necesito troubleshooting"
1. Lee: `OPERATIONS_GUIDE.md` (Sección "Troubleshooting Común")
2. Usa: `k8s-commands.sh` (función `logs-all`, `describe_pod`, etc.)
3. Chequea: `kubectl describe pod <POD_NAME> -n ecommerce-dev`

#### "Necesito ver logs"
1. Usa: `k8s-commands.sh` (función `logs-all`)
2. O: `kubectl logs -f deployment/<SERVICE> -n ecommerce-prod`
3. Kibana: Port-forward a 5601

#### "Necesito escalar servicios"
1. Manual: `kubectl scale deployment api-gateway --replicas=5 -n ecommerce-prod`
2. Automático: Ya configurado via HPA (ver `hpa.yaml`)
3. Verificar: `kubectl get hpa -n ecommerce-prod`

#### "Necesito hacer backup"
1. Usa: `k8s-commands.sh` (función `backup_db`)
2. O: Procedimiento en `OPERATIONS_GUIDE.md`

#### "Necesito entender la arquitectura"
1. Lee: `KUBERNETES_ARCHITECTURE.md`
2. Luego: `OPERATIONS_GUIDE.md`

#### "Necesito configurar seguridad"
1. Lee: `SECURITY_GUIDE.md`
2. Verifica: RBAC en `k8s/security/rbac.yaml`
3. NetworkPolicies: `k8s/infrastructure/network-policies.yaml`

---

## 📊 ESTADÍSTICAS

| Métrica | Valor |
|---------|-------|
| Archivos YAML/JSON | 25+ |
| Archivos Python | 1 |
| Archivos Shell Scripts | 4 |
| Archivos Markdown | 7 |
| Líneas de código YAML | 3000+ |
| Líneas de scripts | 1500+ |
| Líneas de documentación | 8000+ |
| Total de líneas | 12500+ |
| Microservicios | 10 |
| Namespaces | 4 |
| NetworkPolicies | 8+ |
| RBAC Roles | 5+ |
| Services | 15+ |
| Deployments | 10+ |
| StatefulSets | 1 |
| ConfigMaps | 10+ |
| Secrets | 10+ |
| Ingress | 1 |
| PersistentVolumeClaims | 3+ |

---

## ✅ CHECKLIST DE LECTURA

Para nuevo usuario:

- [ ] Leer README.md (inicio)
- [ ] Leer QUICK_START.sh (guía rápida)
- [ ] Leer KUBERNETES_ARCHITECTURE.md (diseño)
- [ ] Leer OPERATIONS_GUIDE.md (operaciones)
- [ ] Leer SECURITY_GUIDE.md (seguridad)
- [ ] Explorar `k8s/` directory
- [ ] Ejecutar `./k8s-deploy.sh dev` (primeros pasos)
- [ ] Verificar pods con `kubectl get pods -n ecommerce-dev`
- [ ] Acceder a Grafana en `http://localhost:3000`
- [ ] Revisar REQUIREMENTS_CHECKLIST.md (validar completitud)

---

## 🔗 REFERENCIAS ÚTILES

### Documentación Externa
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Jaeger Docs](https://www.jaegertracing.io/docs/)

### Herramientas Necesarias
- kubectl (>=1.25)
- helm (>=3.0)
- docker (>= 20.10)
- minikube (opcional, para desarrollo)
- kind (opcional, para CI/CD)

### Ports a Recordar
- API Gateway: 8080
- Grafana: 3000
- Prometheus: 9090
- Kibana: 5601
- Jaeger: 16686
- Eureka: 8761
- MySQL: 3306

---

## 🎓 PRÓXIMOS PASOS RECOMENDADOS

1. **Setup local**: Instalar Minikube y ejecutar `./k8s-deploy.sh dev`
2. **Validar**: Verificar todos los pods running
3. **Monitorear**: Acceder a Grafana y crear dashboards
4. **Test**: Ejecutar `bash k8s/load-testing/run-load-test.sh dev 10 5 1m`
5. **Seguridad**: Implementar Sealed Secrets (ver SECURITY_GUIDE.md)
6. **CI/CD**: Configurar GitHub Actions secrets
7. **Production**: Adaptar para cloud provider (AWS/GCP/Azure)

---

**Última actualización**: 2024  
**Versión**: 1.0  
**Estado**: ✅ COMPLETADO

