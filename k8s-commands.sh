#!/bin/bash

# Colección de comandos útiles para Kubernetes e-Commerce
# Guardar como: k8s-commands.sh
# Uso: source k8s-commands.sh (para tener las funciones disponibles)

# ============================================
# FUNCIONES DE UTILIDAD
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones helper
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# ============================================
# DEPLOYMENT
# ============================================

deploy-dev() {
    info "Desplegando ambiente DEV..."
    ./k8s-deploy.sh dev
}

deploy-qa() {
    info "Desplegando ambiente QA..."
    ./k8s-deploy.sh qa
}

deploy-prod() {
    info "Desplegando ambiente PROD..."
    ./k8s-deploy.sh prod
}

deploy-only-services() {
    local env=${1:-dev}
    info "Desplegando solo servicios en $env (sin infraestructura)..."
    ./k8s-deploy.sh $env skip-infra
}

# ============================================
# ESTADO Y VERIFICACIÓN
# ============================================

check-all() {
    local env=${1:-dev}
    info "Verificando estado general del ambiente $env..."
    echo ""
    echo "=== NAMESPACES ==="
    kubectl get ns | grep ecommerce
    
    echo ""
    echo "=== PODS ==="
    kubectl get pods -n ecommerce-$env -o wide
    
    echo ""
    echo "=== SERVICIOS ==="
    kubectl get svc -n ecommerce-$env
    
    echo ""
    echo "=== INGRESS ==="
    kubectl get ingress -n ecommerce-$env
    
    echo ""
    echo "=== PERSISTENTES ==="
    kubectl get pvc -n ecommerce-$env
}

check-health() {
    local env=${1:-dev}
    info "Verificando health de servicios en $env..."
    
    for pod in $(kubectl get pods -n ecommerce-$env -o jsonpath='{.items[*].metadata.name}'); do
        status=$(kubectl get pod -n ecommerce-$env $pod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        echo "- $pod: $status"
    done
}

wait-ready() {
    local env=${1:-dev}
    local timeout=${2:-300}
    info "Esperando a que todos los pods estén ready en $env (timeout: ${timeout}s)..."
    kubectl wait --for=condition=ready pod --all -n ecommerce-$env --timeout=${timeout}s
}

# ============================================
# LOGS
# ============================================

logs-all() {
    local env=${1:-dev}
    local service=${2:-}
    
    if [ -z "$service" ]; then
        warn "Especificar servicio. Uso: logs-all <env> <service>"
        return 1
    fi
    
    kubectl logs -n ecommerce-$env \
        -l app=$service \
        -f --all-containers=true --tail=50
}

logs-pod() {
    local env=${1:-dev}
    local pod=${2:-}
    
    if [ -z "$pod" ]; then
        warn "Especificar pod. Uso: logs-pod <env> <pod>"
        return 1
    fi
    
    kubectl logs -n ecommerce-$env $pod -f --tail=100
}

logs-previous() {
    local env=${1:-dev}
    local pod=${2:-}
    
    if [ -z "$pod" ]; then
        warn "Especificar pod. Uso: logs-previous <env> <pod>"
        return 1
    fi
    
    kubectl logs -n ecommerce-$env $pod --previous
}

tail-logs() {
    local env=${1:-dev}
    local lines=${2:-50}
    
    info "Últimas $lines líneas de logs en $env..."
    kubectl logs -n ecommerce-$env \
        -l app -f \
        --all-containers=true --tail=$lines
}

# ============================================
# DEBUGGING
# ============================================

describe-pod() {
    local env=${1:-dev}
    local pod=${2:-}
    
    if [ -z "$pod" ]; then
        warn "Especificar pod. Uso: describe-pod <env> <pod>"
        return 1
    fi
    
    kubectl describe pod -n ecommerce-$env $pod
}

exec-pod() {
    local env=${1:-dev}
    local pod=${2:-}
    
    if [ -z "$pod" ]; then
        warn "Especificar pod. Uso: exec-pod <env> <pod>"
        return 1
    fi
    
    info "Conectando a $pod en ambiente $env..."
    kubectl exec -it -n ecommerce-$env $pod -- /bin/bash
}

port-forward() {
    local env=${1:-dev}
    local pod=${2:-}
    local local_port=${3:-8080}
    local remote_port=${4:-8080}
    
    if [ -z "$pod" ]; then
        warn "Especificar pod. Uso: port-forward <env> <pod> [local_port] [remote_port]"
        return 1
    fi
    
    info "Port-forward: localhost:$local_port -> $pod:$remote_port"
    kubectl port-forward -n ecommerce-$env $pod $local_port:$remote_port
}

# ============================================
# MÉTRICAS Y RECURSOS
# ============================================

metrics() {
    local env=${1:-dev}
    info "Uso de recursos en ambiente $env..."
    
    echo ""
    echo "=== PODS ==="
    kubectl top pods -n ecommerce-$env --sort-by=cpu
    
    echo ""
    echo "=== NODOS ==="
    kubectl top nodes
}

metrics-watch() {
    local env=${1:-dev}
    info "Monitoreando métricas en tiempo real en $env..."
    kubectl top pods -n ecommerce-$env --sort-by=cpu -w
}

metrics-resource() {
    local env=${1:-dev}
    info "Detalles de uso de recursos en $env..."
    kubectl get pods -n ecommerce-$env \
        -o custom-columns=NAME:.metadata.name,\
CPU_REQ:.spec.containers[*].resources.requests.cpu,\
CPU_LIM:.spec.containers[*].resources.limits.cpu,\
MEM_REQ:.spec.containers[*].resources.requests.memory,\
MEM_LIM:.spec.containers[*].resources.limits.memory
}

# ============================================
# ESCALADO
# ============================================

scale-deployment() {
    local env=${1:-dev}
    local deployment=${2:-}
    local replicas=${3:-}
    
    if [ -z "$deployment" ] || [ -z "$replicas" ]; then
        warn "Uso: scale-deployment <env> <deployment> <replicas>"
        return 1
    fi
    
    info "Escalando $deployment a $replicas replicas en $env..."
    kubectl scale deployment/$deployment -n ecommerce-$env --replicas=$replicas
}

check-hpa() {
    local env=${1:-dev}
    info "Estado de HPA en ambiente $env..."
    kubectl get hpa -n ecommerce-$env
    echo ""
    kubectl describe hpa -n ecommerce-$env
}

watch-hpa() {
    local env=${1:-dev}
    info "Monitoreando HPA en tiempo real..."
    kubectl get hpa -n ecommerce-$env -w
}

# ============================================
# ACTUALIZACIONES
# ============================================

update-image() {
    local env=${1:-dev}
    local deployment=${2:-}
    local image=${3:-}
    
    if [ -z "$deployment" ] || [ -z "$image" ]; then
        warn "Uso: update-image <env> <deployment> <image:tag>"
        return 1
    fi
    
    info "Actualizando imagen de $deployment a $image..."
    kubectl set image deployment/$deployment \
        $deployment=$image \
        -n ecommerce-$env
    
    info "Monitoreando rollout..."
    kubectl rollout status deployment/$deployment -n ecommerce-$env
}

rollback-deployment() {
    local env=${1:-dev}
    local deployment=${2:-}
    
    if [ -z "$deployment" ]; then
        warn "Uso: rollback-deployment <env> <deployment>"
        return 1
    fi
    
    warn "Haciendo rollback de $deployment..."
    kubectl rollout undo deployment/$deployment -n ecommerce-$env
    kubectl rollout status deployment/$deployment -n ecommerce-$env
}

rollout-history() {
    local env=${1:-dev}
    local deployment=${2:-}
    
    if [ -z "$deployment" ]; then
        warn "Uso: rollout-history <env> <deployment>"
        return 1
    fi
    
    info "Historial de rollouts de $deployment..."
    kubectl rollout history deployment/$deployment -n ecommerce-$env
}

helm-upgrade() {
    local env=${1:-dev}
    local tag=${2:-0.1.0}
    
    info "Actualizando Helm release con tag $tag en ambiente $env..."
    helm upgrade ecommerce ./k8s/helm/ecommerce-microservices \
        -n ecommerce-$env \
        --values ./k8s/helm/ecommerce-microservices/values/$env.yaml \
        --set image.tag=$tag \
        --wait
}

helm-rollback() {
    local env=${1:-dev}
    local revision=${2:-0}
    
    info "Rollback de Helm release en $env a revisión $revision..."
    helm rollback ecommerce $revision -n ecommerce-$env
}

# ============================================
# BASE DE DATOS
# ============================================

db-shell() {
    local env=${1:-dev}
    info "Conectando a MySQL en $env..."
    local password=$(kubectl get secret -n ecommerce-$env mysql-credentials \
        -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
    
    kubectl exec -it -n ecommerce-$env mysql-0 -- \
        mysql -uroot -p"$password"
}

db-backup() {
    local env=${1:-dev}
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="backup-${env}-${timestamp}.sql"
    
    info "Creando backup de base de datos $env..."
    local password=$(kubectl get secret -n ecommerce-$env mysql-credentials \
        -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
    
    kubectl exec -n ecommerce-$env mysql-0 -- \
        mysqldump -uroot -p"$password" --all-databases > "$backup_file"
    
    info "Backup creado: $backup_file"
}

db-restore() {
    local env=${1:-dev}
    local backup_file=${2:-}
    
    if [ ! -f "$backup_file" ]; then
        error "Archivo de backup no encontrado: $backup_file"
        return 1
    fi
    
    warn "Restaurando base de datos desde $backup_file..."
    local password=$(kubectl get secret -n ecommerce-$env mysql-credentials \
        -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
    
    kubectl exec -i -n ecommerce-$env mysql-0 -- \
        mysql -uroot -p"$password" < "$backup_file"
    
    info "Restauración completada"
}

# ============================================
# SECRETOS
# ============================================

list-secrets() {
    local env=${1:-dev}
    info "Secretos en ambiente $env..."
    kubectl get secrets -n ecommerce-$env
}

view-secret() {
    local env=${1:-dev}
    local secret=${2:-}
    
    if [ -z "$secret" ]; then
        warn "Uso: view-secret <env> <secret-name>"
        return 1
    fi
    
    warn "Mostrando secret (valores en base64)..."
    kubectl get secret -n ecommerce-$env $secret -o yaml
}

decode-secret() {
    local env=${1:-dev}
    local secret=${2:-}
    local key=${3:-}
    
    if [ -z "$secret" ] || [ -z "$key" ]; then
        warn "Uso: decode-secret <env> <secret-name> <key>"
        return 1
    fi
    
    kubectl get secret -n ecommerce-$env $secret \
        -o jsonpath="{.data.$key}" | base64 -d
    echo ""
}

# ============================================
# MONITOREO
# ============================================

access-grafana() {
    info "Abriendo Grafana..."
    echo "URL: https://grafana.ecommerce.local"
    echo "Usuario: admin"
    echo "Contraseña: admin123"
}

access-prometheus() {
    info "Abriendo Prometheus..."
    echo "URL: https://prometheus.ecommerce.local"
}

access-jaeger() {
    info "Abriendo Jaeger..."
    echo "URL: https://jaeger.ecommerce.local"
}

access-kibana() {
    info "Abriendo Kibana..."
    echo "URL: https://kibana.ecommerce.local"
}

# ============================================
# LOAD TESTING
# ============================================

load-test() {
    local env=${1:-dev}
    local users=${2:-100}
    local spawn_rate=${3:-10}
    local run_time=${4:-5m}
    
    local api_url="http://api-gateway.ecommerce-${env}.svc.cluster.local:8080"
    
    info "Iniciando test de carga..."
    info "API: $api_url"
    info "Usuarios: $users | Spawn Rate: $spawn_rate/s | Duración: $run_time"
    
    locust -f k8s/load-testing/locustfile.py \
        --host="$api_url" \
        --users=$users \
        --spawn-rate=$spawn_rate \
        --run-time=$run_time \
        --csv=load-test-results \
        --html=load-test-report.html
    
    info "Resultados guardados:"
    echo "  - load-test-results_stats.csv"
    echo "  - load-test-report.html"
}

load-test-distributed() {
    local env=${1:-dev}
    
    info "Desplegando Locust distribuido..."
    kubectl apply -f k8s/load-testing/locust-deployment.yaml
    
    info "Acceder a: http://locust.ecommerce.local"
}

# ============================================
# LIMPEZA
# ============================================

clean-namespace() {
    local env=${1:-dev}
    
    warn "Esto eliminará TODO en el namespace ecommerce-$env"
    read -p "¿Estás seguro? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        info "Limpiando namespace..."
        kubectl delete all --all -n ecommerce-$env
        kubectl delete pvc --all -n ecommerce-$env
    fi
}

delete-namespace() {
    local env=${1:-dev}
    
    error "Esto ELIMINARÁ completamente el namespace ecommerce-$env"
    read -p "Escribe 'SI' para confirmar: " confirmation
    if [ "$confirmation" = "SI" ]; then
        warn "Eliminando namespace..."
        kubectl delete namespace ecommerce-$env
    fi
}

# ============================================
# INFORMACIÓN Y AYUDA
# ============================================

help() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════╗
║         e-Commerce Kubernetes - Funciones Disponibles         ║
╚════════════════════════════════════════════════════════════════╝

DEPLOYMENT:
  deploy-dev              Desplegar ambiente DEV
  deploy-qa               Desplegar ambiente QA
  deploy-prod             Desplegar ambiente PROD
  deploy-only-services    Desplegar solo microservicios

VERIFICACIÓN:
  check-all <env>         Estado general
  check-health <env>      Health de servicios
  wait-ready <env>        Esperar a que pods estén ready

LOGS:
  logs-all <env> <svc>    Logs de servicio
  logs-pod <env> <pod>    Logs de pod específico
  logs-previous <env>     Logs del pod anterior (crashed)
  tail-logs <env> [n]     Últimas n líneas

DEBUG:
  describe-pod <env>      Información detallada del pod
  exec-pod <env> <pod>    Ejecutar bash en pod
  port-forward <env> <pod> [local] [remote]   Port forward

MÉTRICAS:
  metrics <env>           Uso de CPU/memoria
  metrics-watch <env>     Monitorear en tiempo real
  metrics-resource <env>  Detalles de recursos

ESCALADO:
  scale-deployment <env> <depl> <n>  Escalar deployment
  check-hpa <env>         Ver HPA status
  watch-hpa <env>         Monitorear HPA

ACTUALIZACIONES:
  update-image <env> <depl> <img:tag>   Actualizar imagen
  rollback-deployment <env> <depl>      Hacer rollback
  rollout-history <env> <depl>          Ver historial
  helm-upgrade <env> [tag]              Update con Helm
  helm-rollback <env> [rev]             Rollback Helm

BASE DE DATOS:
  db-shell <env>          Conectar a MySQL
  db-backup <env>         Crear backup
  db-restore <env> <file> Restaurar backup

SECRETOS:
  list-secrets <env>      Listar secretos
  view-secret <env> <nom> Ver contenido (base64)
  decode-secret <env> <nom> <key>  Decodificar

MONITOREO:
  access-grafana          URLs de acceso
  access-prometheus
  access-jaeger
  access-kibana

LOAD TESTING:
  load-test <env> [users] [spawn] [time]  Test de carga
  load-test-distributed <env>             Setup Locust K8s

LIMPEZA:
  clean-namespace <env>   Limpiar namespace
  delete-namespace <env>  Eliminar namespace

Argumentos comunes:
  <env>     - dev, qa, prod

Ejemplos:
  check-all dev
  logs-all prod api-gateway
  scale-deployment qa user-service 5
  update-image dev api-gateway myrepo/api:v0.2.0
  load-test prod 200 20 10m

EOF
}

# Mostrar help al cargar el script
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    help
else
    info "Funciones Kubernetes cargadas. Escribir 'help' para ver todas."
fi
