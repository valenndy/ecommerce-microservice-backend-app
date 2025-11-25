# Arquitectura Kubernetes para e-Commerce Microservices

## Descripción General

Este documento describe la arquitectura completa de Kubernetes para el despliegue de los microservicios de e-Commerce. La arquitectura está diseñada para ser escalable, resiliente y segura, siguiendo mejores prácticas de Cloud Native.

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Componentes](#componentes)
3. [Flujo de Comunicación](#flujo-de-comunicación)
4. [Seguridad](#seguridad)
5. [Observabilidad](#observabilidad)
6. [Despliegue y CI/CD](#despliegue-y-cicd)
7. [Escalabilidad](#escalabilidad)
8. [Persistencia](#persistencia)

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  INGRESS LAYER                           │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  NGINX Ingress Controller + cert-manager (TLS)  │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            │                                      │
│  ┌─────────────────────────┴──────────────────────────────┐    │
│  │           API GATEWAY SERVICE LAYER                     │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ API Gateway (Spring Cloud Gateway)               │  │    │
│  │  │ Load Balanced (3 replicas in prod)               │  │    │
│  │  │ Service: api-gateway:8080                        │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Proxy Client (Authentication & Authorization)    │  │    │
│  │  │ OAuth2/JWT Support                               │  │    │
│  │  │ Service: proxy-client:8900                       │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                      │
│  ┌─────────────────────────┴──────────────────────────────┐    │
│  │      INFRASTRUCTURE SERVICES LAYER                     │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Service Discovery (Eureka)                       │  │    │
│  │  │ Service: service-discovery:8761                  │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Cloud Config Server                              │  │    │
│  │  │ Service: cloud-config:9296                       │  │    │
│  │  │ Centralized Configuration Management             │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Zipkin/Jaeger (Distributed Tracing)              │  │    │
│  │  │ Service: zipkin:9411 / jaeger:16686              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                      │
│  ┌─────────────────────────┴──────────────────────────────┐    │
│  │         BUSINESS LOGIC MICROSERVICES                   │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ User Service (8700)                              │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Product Service (8500)                           │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Order Service (8300)                             │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  │ └─> Calls: User, Product, Payment, Shipping    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Payment Service (8400)                           │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Shipping Service (8600)                          │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Favourite Service (8800)                         │  │    │
│  │  │ └─> MySQL Database                              │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                                                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                      │
│  ┌─────────────────────────┴──────────────────────────────┐    │
│  │           MONITORING & OBSERVABILITY LAYER             │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Prometheus (Metrics Collection)                  │  │    │
│  │  │ Service: prometheus:9090                        │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Grafana (Visualization)                          │  │    │
│  │  │ Service: grafana:3000                           │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Elasticsearch + Kibana (Log Storage)             │  │    │
│  │  │ Services: elasticsearch:9200, kibana:5601       │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │ Jaeger (Distributed Tracing)                     │  │    │
│  │  │ Service: jaeger:16686                           │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           STORAGE LAYER (StatefulSets)                 │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │ MySQL Primary Database                           │  │   │
│  │  │ Persistent Volume (PVC): 50Gi (prod)            │  │   │
│  │  │ StatefulSet with 1 replica + backups            │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes

### Namespaces

| Namespace | Propósito | Security Level |
|-----------|-----------|-----------------|
| `ecommerce-dev` | Ambiente de desarrollo | Baseline |
| `ecommerce-qa` | Ambiente de testing | Restricted |
| `ecommerce-prod` | Ambiente de producción | Restricted |
| `monitoring` | Stack de monitoreo | Restricted |
| `logging` | Stack de logging | Restricted |
| `ingress-nginx` | Ingress Controller | Restricted |
| `cert-manager` | TLS Certificate Management | Restricted |

### Microservicios

#### 1. Service Discovery (Eureka)
- **Puerto**: 8761
- **Replicas**: 1 (dev), 2 (qa), 3 (prod)
- **Función**: Registro y descubrimiento de servicios
- **Configuración**: Spring Cloud Eureka Server
- **Health Check**: `/actuator/health`

#### 2. Cloud Config Server
- **Puerto**: 9296
- **Replicas**: 1 (dev), 2 (qa), 3 (prod)
- **Función**: Gestión centralizada de configuración
- **Configuración**: Spring Cloud Config Server
- **ConfigMaps**: Inyectados en los microservicios

#### 3. API Gateway
- **Puerto**: 8080
- **Replicas**: 2 (dev), 2 (qa), 3 (prod)
- **Función**: Punto de entrada único para todas las APIs
- **Configuración**: Spring Cloud Gateway
- **Rate Limiting**: Habilitado en producción
- **Endpoint Público**: https://api.ecommerce.local

#### 4. Proxy Client
- **Puerto**: 8900
- **Replicas**: 2 (dev), 2 (qa), 3 (prod)
- **Función**: Autenticación y autorización (OAuth2/JWT)
- **Configuración**: Spring Security + Spring Cloud

#### 5-10. Microservicios de Negocio
- **User Service** (8700)
- **Product Service** (8500)
- **Favourite Service** (8800)
- **Order Service** (8300)
- **Payment Service** (8400)
- **Shipping Service** (8600)

**Características comunes**:
- Replicas: 1 (dev), 2 (qa), 3 (prod)
- Base de datos: MySQL dedicada por servicio
- Health Checks: Liveness + Readiness probes
- Circuit Breaker: Resilience4j
- Distributed Tracing: Zipkin/Jaeger

## Flujo de Comunicación

```
Usuario/Cliente
      │
      ▼
┌─────────────┐
│   Ingress   │ (HTTPS con Let's Encrypt)
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  API Gateway    │ (Enrutamiento, Rate Limiting)
└────────┬────────┘
         │
    ┌────┴──────┬─────────────┬──────────────┐
    ▼           ▼             ▼              ▼
┌────────┐  ┌────────┐  ┌────────┐  ┌───────────┐
│ User   │  │Product │  │ Order  │  │ Favourite │
│Service │  │Service │  │Service │  │ Service   │
└────┬───┘  └────┬───┘  └───┬────┘  └─────┬─────┘
     │           │           │            │
     │           ▼           │            │
     │      ┌─────────┐      │            │
     │      │ Product │      │            │
     │      │Service  │      │            │
     │      └─────────┘      │            │
     │                       │            │
     │           ┌───────────┼────────────┘
     │           ▼           ▼
     │      ┌──────────┐ ┌──────────┐
     │      │ Payment  │ │ Shipping │
     │      │ Service  │ │ Service  │
     │      └──────────┘ └──────────┘
     │
     └─────► Service Discovery (Eureka)
     
     Todos los servicios reportan a:
     - Prometheus (métricas)
     - Zipkin/Jaeger (tracing)
     - ELK Stack (logs)
```

## Seguridad

### Pod Security Standards
- **Dev**: Baseline (permite algunos privilegios)
- **QA/Prod**: Restricted (máximo aislamiento)

### RBAC
- ServiceAccounts con permisos mínimos necesarios
- ClusterRoles solo lectura en la mayoría de casos
- Namespace isolation

### NetworkPolicies
- Tráfico ingress solo desde API Gateway
- Comunicación inter-servicio permitida
- Aislamiento de namespaces

### Secrets Management
- Secretos en Kubernetes (en dev)
- External Secrets Operator (en prod)
- Rotación automática de credenciales

### Pod Security
- Non-root containers
- Read-only filesystem
- Capacidades Linux mínimas (CAP_DROP ALL)
- Syscall filtering

## Observabilidad

### Métricas
- **Prometheus**: Scrape interval 15s
- **Fuentes**: 
  - Spring Boot Actuator endpoints
  - JVM metrics
  - Application-specific metrics
  - Kubernetes metrics (nodes, pods)

### Logs
- **Elasticsearch**: Almacenamiento centralizado
- **Kibana**: Visualización y búsqueda
- **Logstash**: Procesamiento
- **Retention**: 30 días configurables

### Tracing Distribuido
- **Jaeger**: All-in-one deployment
- **Integración**: Spring Cloud Sleuth
- **Zipkin Compatibility**: Soportado
- **Sampling**: 1 de cada 10 traces en prod

### Dashboards Grafana
1. **Kubernetes Overview**: Node, pod, network metrics
2. **Application Metrics**: Request rate, latency, errors
3. **Database Performance**: Query times, connections
4. **Business Metrics**: Orders, revenue, conversion rates

## Despliegue y CI/CD

### Pipeline GitHub Actions
1. **Build Stage**:
   - Checkout código
   - Build Maven (11 threads paralelos)
   - Unit tests
   - Docker build & push

2. **Security Stage**:
   - Image scanning con Trivy
   - SBOM generation
   - Vulnerability reporting

3. **Deploy Stages**:
   - Dev: Automático en rama `develop`
   - Prod: Manual approval + automático en rama `master`

### Estrategias de Despliegue

#### Rolling Update (Default)
- maxSurge: 1 pod extra
- maxUnavailable: 0 pods

#### Canary Deployment (Prod)
- 10% de tráfico a versión nueva
- Monitoreo automático de métricas
- Rollback si tasa de error > 5%

#### Blue-Green Deployment
- Mantener dos versiones completas
- Switch instantáneo de tráfico
- Rollback rápido

## Escalabilidad

### Horizontal Pod Autoscaler (HPA)
- **Métricas**: CPU (70%) y Memory (80%)
- **Min/Max Replicas**:
  - Dev: 1-3
  - QA: 2-5
  - Prod: 3-20
- **Scale-down**: Estabilización de 300s
- **Scale-up**: Sin delay, 30s entre cambios

### KEDA (Eventos)
- Escalado basado en eventos de base de datos
- Escalado basado en longitud de colas
- Escalado basado en latencia HTTP

### Quality of Service (QoS)
- **Burstable**: Requests definidos, sin limits estrictos
- **Guaranteed**: Dev con requests = limits
- **BestEffort**: Monitoring stack sin guarantees

### Resource Limits por Ambiente
| Ambiente | CPU Request | CPU Limit | Memory Request | Memory Limit |
|----------|------------|-----------|----------------|--------------|
| Dev | 100m | 300m | 128Mi | 256Mi |
| QA | 200m | 400m | 192Mi | 384Mi |
| Prod | 500m | 1000m | 512Mi | 1Gi |

## Persistencia

### Storage Classes
- **ecommerce-mysql-storage**: Local provisioner
- **Replication Factor**: 3 (configurado)
- **Allow Volume Expansion**: Habilitado

### Persistent Volumes
- **Tamaño por ambiente**:
  - Dev: 10Gi
  - QA: 20Gi
  - Prod: 50Gi
- **Access Mode**: ReadWriteOnce
- **Binding**: WaitForFirstConsumer

### Base de Datos
- **Tipo**: MySQL 8.0
- **Configuración**: StatefulSet
- **Backups**: Pod-based backup jobs
- **Replicación**: Master-Slave (opcional)

### Data Migration
- Flyway/Liquibase para migraciones
- Ejecutadas automáticamente durante deployment
- Rollback automático si falla

## Acceso a Servicios

### Endpoints Públicos (HTTPS)
- **API Gateway**: https://api.ecommerce.local
- **Eureka**: https://eureka.ecommerce.local
- **Cloud Config**: https://config.ecommerce.local
- **Grafana**: https://grafana.ecommerce.local (admin/admin123)
- **Prometheus**: https://prometheus.ecommerce.local
- **Jaeger**: https://jaeger.ecommerce.local
- **Kibana**: https://kibana.ecommerce.local

### Internal Communication
- Service DNS: `<service-name>.<namespace>.svc.cluster.local`
- Ejemplo: `user-service.ecommerce-prod.svc.cluster.local:8700`

## Mantenimiento y Operaciones

### Monitoreo de Salud
```bash
# Verificar pods
kubectl get pods -n ecommerce-prod

# Ver logs de un pod
kubectl logs -n ecommerce-prod <pod-name> -f

# Describir un pod (problemas)
kubectl describe pod -n ecommerce-prod <pod-name>

# Porcentaje de uso de recursos
kubectl top pods -n ecommerce-prod
```

### Escalado Manual
```bash
# Escalar un deployment
kubectl scale deployment user-service -n ecommerce-prod --replicas=5

# Ver HPA status
kubectl get hpa -n ecommerce-prod
```

### Updates y Rollbacks
```bash
# Update con Helm
helm upgrade ecommerce ./k8s/helm/ecommerce-microservices \
  -n ecommerce-prod \
  --values values/prod.yaml

# Rollback a versión anterior
helm rollback ecommerce 1 -n ecommerce-prod
```

## Próximos Pasos

1. Configurar backups automáticos
2. Implementar Service Mesh (Istio/Linkerd)
3. Configurar Disaster Recovery
4. Implementar GitOps con ArgoCD
5. Optimización de costos

## Referencia de Comandos Útiles

```bash
# Deploy inicial
./k8s-deploy.sh prod

# Deploy solo microservicios (sin infraestructura)
./k8s-deploy.sh prod skip-infra

# Verificar estado general
kubectl get all -n ecommerce-prod

# Ejecutar test de carga
locust -f k8s/load-testing/locustfile.py \
  --host=http://api-gateway.ecommerce-prod.svc.cluster.local:8080

# Acceder a logs centralizados
# Abrir http://kibana.ecommerce.local
```

---

**Versión**: 1.0
**Fecha**: 2024
**Mantenedor**: DevOps Team
