# Guía de Operaciones - e-Commerce Kubernetes

## Tabla de Contenidos
1. [Deployment Inicial](#deployment-inicial)
2. [Monitoreo y Troubleshooting](#monitoreo-y-troubleshooting)
3. [Escalado](#escalado)
4. [Updates y Rollbacks](#updates-y-rollbacks)
5. [Backup y Disaster Recovery](#backup-y-disaster-recovery)
6. [Performance Tuning](#performance-tuning)
7. [Security Operations](#security-operations)

## Deployment Inicial

### Prerequisitos
- Kubernetes 1.25+ (Minikube, Kind, EKS, GKE, AKS)
- kubectl configurado
- Helm 3.0+
- Docker (para construir imágenes localmente)

### Pasos de Deployment

```bash
# 1. Clonar el repositorio
git clone https://github.com/SelimHorri/ecommerce-microservice-backend-app.git
cd ecommerce-microservice-backend-app

# 2. Build de imágenes (opcional si usas imágenes públicas)
./mvnw clean package
docker build -f service-discovery/Dockerfile -t selimhorri/service-discovery-ecommerce-boot:0.1.0 ./service-discovery
# ... repetir para cada servicio

# 3. Deploy a ambiente DEV
chmod +x k8s-deploy.sh
./k8s-deploy.sh dev

# 4. Verificar estado
kubectl get pods -n ecommerce-dev
kubectl get svc -n ecommerce-dev
kubectl get ingress -n ecommerce-dev

# 5. Esperar a que todos los pods estén ready
kubectl wait --for=condition=ready pod \
  --all -n ecommerce-dev --timeout=600s
```

### Configuración de Hosts Locales

Para acceder a través de hostnames, agregar a `/etc/hosts`:

```
127.0.0.1  api.ecommerce.local
127.0.0.1  eureka.ecommerce.local
127.0.0.1  config.ecommerce.local
127.0.0.1  grafana.ecommerce.local
127.0.0.1  prometheus.ecommerce.local
127.0.0.1  jaeger.ecommerce.local
127.0.0.1  kibana.ecommerce.local
```

O si usas Minikube:
```bash
minikube ip  # Obtener IP del cluster
# Agregar esa IP a los hosts anteriores
```

## Monitoreo y Troubleshooting

### Ver estado de recursos

```bash
# Todos los pods en un namespace
kubectl get pods -n ecommerce-prod

# Pods con detalles (nodos, IPs internas)
kubectl get pods -n ecommerce-prod -o wide

# Recursos de todos los tipos
kubectl get all -n ecommerce-prod

# Eventos recientes
kubectl get events -n ecommerce-prod --sort-by='.lastTimestamp'
```

### Inspeccionar problemas

```bash
# Ver logs de un pod
kubectl logs -n ecommerce-prod <pod-name>

# Ver últimas 100 líneas
kubectl logs -n ecommerce-prod <pod-name> --tail=100

# Ver logs en tiempo real
kubectl logs -n ecommerce-prod <pod-name> -f

# Ver logs de contenedor anterior (si crasheó)
kubectl logs -n ecommerce-prod <pod-name> --previous

# Describir pod (eventos y configuración)
kubectl describe pod -n ecommerce-prod <pod-name>

# Ejecutar comando en un pod
kubectl exec -it -n ecommerce-prod <pod-name> -- /bin/bash

# Port-forward para debug
kubectl port-forward -n ecommerce-prod <pod-name> 8080:8080
```

### Métricas en tiempo real

```bash
# Uso de recursos de pods
kubectl top pods -n ecommerce-prod

# Uso de recursos de nodos
kubectl top nodes

# HPA status
kubectl get hpa -n ecommerce-prod -w

# Ver métricas en Prometheus
# http://prometheus.ecommerce.local:9090
```

### Health checks

```bash
# Verificar readiness probe
kubectl get pod -n ecommerce-prod <pod-name> -o jsonpath='{.status.conditions[?(@.type=="Ready")]}'

# Verificar liveness probe
kubectl get pod -n ecommerce-prod <pod-name> -o jsonpath='{.status.conditions[?(@.type=="Initialized")]}'

# Ejecutar health endpoint manualmente
kubectl exec -n ecommerce-prod <pod-name> -- curl localhost:8080/actuator/health
```

## Escalado

### Escalado Manual

```bash
# Escalar un deployment
kubectl scale deployment api-gateway -n ecommerce-prod --replicas=5

# Escalar un statefulset
kubectl scale statefulset mysql -n ecommerce-prod --replicas=3
```

### Verificar HPA

```bash
# Ver estado de HPA
kubectl get hpa -n ecommerce-prod

# Ver detalles de HPA
kubectl describe hpa -n ecommerce-prod api-gateway

# Monitorear HPA en tiempo real
kubectl get hpa -n ecommerce-prod -w
```

### Ajustar políticas de HPA

```bash
# Editar HPA
kubectl edit hpa -n ecommerce-prod api-gateway

# Cambiar límites de escalado
kubectl patch hpa api-gateway -n ecommerce-prod \
  -p '{"spec":{"minReplicas":2,"maxReplicas":15}}'

# Cambiar objetivo de CPU
kubectl patch hpa api-gateway -n ecommerce-prod \
  -p '{"spec":{"targetCPUUtilizationPercentage":80}}'
```

## Updates y Rollbacks

### Update de imagen

```bash
# Actualizar imagen de un deployment
kubectl set image deployment/api-gateway \
  api-gateway=selimhorri/api-gateway-ecommerce-boot:new-tag \
  -n ecommerce-prod

# Monitorear el rollout
kubectl rollout status deployment/api-gateway -n ecommerce-prod

# Ver historial de rollouts
kubectl rollout history deployment/api-gateway -n ecommerce-prod

# Ver detalles de una revisión
kubectl rollout history deployment/api-gateway -n ecommerce-prod --revision=2
```

### Rollback

```bash
# Rollback a versión anterior
kubectl rollout undo deployment/api-gateway -n ecommerce-prod

# Rollback a versión específica
kubectl rollout undo deployment/api-gateway -n ecommerce-prod --to-revision=2

# Verificar estado después del rollback
kubectl get pods -n ecommerce-prod
```

### Update con Helm

```bash
# Ver valores actuales
helm get values ecommerce -n ecommerce-prod

# Update con nuevas imágenes
helm upgrade ecommerce ./k8s/helm/ecommerce-microservices \
  -n ecommerce-prod \
  --values ./k8s/helm/ecommerce-microservices/values/prod.yaml \
  --set image.tag=v0.2.0 \
  --wait \
  --timeout 10m

# Ver historial de releases
helm history ecommerce -n ecommerce-prod

# Rollback a release anterior
helm rollback ecommerce 1 -n ecommerce-prod
```

## Backup y Disaster Recovery

### Backup de Base de Datos

```bash
# Crear backup manual
kubectl exec -it -n ecommerce-prod mysql-0 -- mysqldump \
  -uroot -p$(kubectl get secret -n ecommerce-prod mysql-credentials \
  -o jsonpath='{.data.root-password}' | base64 -d) \
  --all-databases > backup-$(date +%Y%m%d_%H%M%S).sql

# Ver volúmenes persistentes
kubectl get pvc -n ecommerce-prod

# Snapshot de volumen
kubectl get volumesnapshotclass
```

### Restore de Base de Datos

```bash
# Conectar a MySQL
kubectl exec -it -n ecommerce-prod mysql-0 -- mysql \
  -uroot -p$(kubectl get secret -n ecommerce-prod mysql-credentials \
  -o jsonpath='{.data.root-password}' | base64 -d)

# Dentro de MySQL:
# SOURCE /path/to/backup.sql;
```

### Backup de ConfigMaps y Secrets

```bash
# Backup de ConfigMaps
kubectl get configmap -n ecommerce-prod -o yaml > configmaps-backup.yaml

# Backup de Secrets (CUIDADO: contiene credenciales)
kubectl get secret -n ecommerce-prod -o yaml > secrets-backup.yaml

# Backup de todo
kubectl get all -n ecommerce-prod -o yaml > full-backup-$(date +%Y%m%d).yaml
```

### Restore

```bash
# Restaurar ConfigMaps
kubectl apply -f configmaps-backup.yaml

# Restaurar Secrets
kubectl apply -f secrets-backup.yaml
```

## Performance Tuning

### Ajustar recursos de pods

```bash
# Ver consumo actual
kubectl top pods -n ecommerce-prod

# Editar deployment para cambiar recursos
kubectl set resources deployment api-gateway \
  -n ecommerce-prod \
  --limits=cpu=1000m,memory=1Gi \
  --requests=cpu=500m,memory=512Mi
```

### Optimizar base de datos

```bash
# Ver configuración de MySQL
kubectl exec -it -n ecommerce-prod mysql-0 -- \
  mysql -uroot -p<password> -e "SHOW VARIABLES;"

# Verificar índices
kubectl exec -it -n ecommerce-prod mysql-0 -- \
  mysql -uroot -p<password> ecommerce \
  -e "SHOW INDEX FROM products;"

# Optimizar tabla
kubectl exec -it -n ecommerce-prod mysql-0 -- \
  mysql -uroot -p<password> ecommerce \
  -e "OPTIMIZE TABLE products;"
```

### Connection pooling

```bash
# Ajustar pool size en ConfigMap
kubectl edit configmap -n ecommerce-prod ecommerce-config

# Agregar/modificar:
# spring.datasource.hikari.maximum-pool-size=20
# spring.datasource.hikari.minimum-idle=5
```

## Security Operations

### Verificar SecurityPolicies

```bash
# Ver Pod Security Policies
kubectl get psp

# Ver restricciones en namespace
kubectl get namespace ecommerce-prod -o yaml | grep pod-security

# Ver Network Policies
kubectl get networkpolicies -n ecommerce-prod

# Ver RBAC
kubectl get rolebindings -n ecommerce-prod
kubectl get clusterrolebindings | grep ecommerce
```

### Auditoría

```bash
# Ver eventos de RBAC
kubectl get events -n ecommerce-prod --field-selector involvedObject.kind=Pod

# Logs del API server (si tienes acceso)
kubectl logs -n kube-system -l component=kube-apiserver
```

### Actualizar Secrets

```bash
# Editar secret
kubectl edit secret -n ecommerce-prod mysql-credentials

# O actualizar desde archivo
kubectl create secret generic mysql-credentials \
  --from-literal=root-password=newpassword \
  --from-literal=user-password=newpassword \
  -n ecommerce-prod --dry-run=client -o yaml | kubectl apply -f -

# Nota: Los pods necesitarán ser reiniciados para usar los nuevos secrets
kubectl rollout restart deployment/user-service -n ecommerce-prod
```

### Rotación de certificados

```bash
# Certificados de Let's Encrypt se rotan automáticamente
# Para ver certificados actuales:
kubectl get certificate -n ecommerce-prod

# Ver detalles de un certificado
kubectl describe certificate api-ecommerce-tls -n ecommerce-prod

# Forzar renovación
kubectl delete secret api-ecommerce-tls -n ecommerce-prod
# cert-manager creará uno nuevo automáticamente
```

### Escaneo de vulnerabilidades

```bash
# Escanear todas las imágenes corriendo
for pod in $(kubectl get pods -n ecommerce-prod -o jsonpath='{.items[*].metadata.name}'); do
  image=$(kubectl get pod $pod -n ecommerce-prod -o jsonpath='{.spec.containers[0].image}')
  echo "Scanning $pod: $image"
  trivy image "$image"
done
```

## Casos de Uso Comunes

### Un servicio está en CrashLoopBackOff

```bash
# 1. Ver el error
kubectl logs -n ecommerce-prod <pod-name> --previous

# 2. Verificar configuración
kubectl get pod -n ecommerce-prod <pod-name> -o yaml

# 3. Verificar dependencias (base de datos, otro servicio)
kubectl logs -n ecommerce-prod mysql-0

# 4. Aumentar recursos si es necesario
kubectl set resources deployment/<service> \
  -n ecommerce-prod \
  --limits=memory=1Gi

# 5. Reiniciar pod
kubectl delete pod -n ecommerce-prod <pod-name>
```

### Alto uso de CPU

```bash
# Identificar pod problemático
kubectl top pods -n ecommerce-prod --sort-by=cpu

# Ver traces de CPU en Prometheus
# Ir a http://prometheus.ecommerce.local/graph
# Query: container_cpu_usage_seconds_total{namespace="ecommerce-prod"}

# Escalar servicio
kubectl scale deployment <service> -n ecommerce-prod --replicas=5
```

### Base de datos llena

```bash
# Ver uso de almacenamiento
kubectl get pvc -n ecommerce-prod

# Expandir PVC
kubectl patch pvc mysql-pvc -n ecommerce-prod \
  -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'

# Limpiar datos antiguos en MySQL
kubectl exec -it -n ecommerce-prod mysql-0 -- mysql \
  -uroot -p<password> ecommerce \
  -e "DELETE FROM orders WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);"
```

---

**Para más información**, consultar:
- KUBERNETES_ARCHITECTURE.md (arquitectura general)
- Documentación oficial de Kubernetes: https://kubernetes.io/docs/
- Documentación de Helm: https://helm.sh/docs/
