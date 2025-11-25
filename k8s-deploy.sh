#!/bin/bash

# Script de inicialización y deployment de la arquitectura Kubernetes
# para el proyecto eCommerce Microservices

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones auxiliares
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificación de herramientas necesarias
check_requirements() {
    print_header "Verificando requisitos"
    
    # Herramientas requeridas
    local tools=("kubectl" "helm" "docker")
    
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool no está instalado"
            exit 1
        else
            print_info "$tool: $(${tool} version 2>&1 | head -1)"
        fi
    done
}

# Crear namespaces
create_namespaces() {
    print_header "Creando namespaces"
    
    kubectl apply -f k8s/namespaces/namespaces.yaml
    
    print_info "Namespaces creados:"
    kubectl get ns | grep ecommerce
}

# Crear infraestructura
setup_infrastructure() {
    print_header "Configurando infraestructura"
    
    # NetworkPolicies se configuran automáticamente en el Helm chart
    print_info "NetworkPolicies se desplegarán automáticamente con Helm"
    
    # RBAC
    print_info "Aplicando configuración RBAC..."
    kubectl apply -f k8s/security/rbac.yaml
    
    # Pod Security
    print_info "Aplicando Pod Security Standards..."
    kubectl apply -f k8s/security/pod-security.yaml
}

# Instalar Ingress Controller
install_ingress_controller() {
    print_header "Instalando NGINX Ingress Controller"
    
    if ! kubectl get namespace ingress-nginx &> /dev/null; then
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update
        helm install ingress-nginx ingress-nginx/ingress-nginx \
            --namespace ingress-nginx \
            --create-namespace \
            --set controller.service.type=LoadBalancer
        print_info "NGINX Ingress Controller instalado"
    else
        print_warning "NGINX Ingress Controller ya existe"
    fi
}

# Instalar cert-manager para TLS
install_cert_manager() {
    print_header "Instalando cert-manager"
    
    if ! kubectl get namespace cert-manager &> /dev/null; then
        helm repo add jetstack https://charts.jetstack.io
        helm repo update
        helm install cert-manager jetstack/cert-manager \
            --namespace cert-manager \
            --create-namespace \
            --set installCRDs=true
        print_info "cert-manager instalado"
    else
        print_warning "cert-manager ya existe"
    fi
}

# Configurar ClusterIssuer para Let's Encrypt
configure_letsencrypt() {
    print_header "Configurando Let's Encrypt"
    
    kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@ecommerce.local
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@ecommerce.local
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    print_info "Let's Encrypt configurado"
}

# Instalar Persistent Storage
setup_storage() {
    print_header "Configurando almacenamiento persistente"
    
    kubectl apply -f k8s/persistence/mysql-storage.yaml
    print_info "Almacenamiento persistente configurado"
}

# Instalar monitoring stack
install_monitoring() {
    print_header "Instalando stack de monitoreo"
    
    # Prometheus
    kubectl apply -f k8s/monitoring/prometheus.yaml
    print_info "Prometheus instalado"
    
    # Grafana
    kubectl apply -f k8s/monitoring/grafana.yaml
    print_info "Grafana instalado"
    
    # Jaeger
    kubectl apply -f k8s/monitoring/jaeger.yaml
    print_info "Jaeger instalado"
}

# Instalar logging stack
install_logging() {
    print_header "Instalando stack de logging"
    
    kubectl apply -f k8s/logging/elk-stack.yaml
    print_info "ELK Stack instalado"
}

# Deploy microservicios
deploy_microservices() {
    print_header "Desplegando microservicios"
    
    local environment=${1:-dev}
    
    print_info "Desplegando a ambiente: $environment"
    
    helm repo add ecommerce ./k8s/helm 2>/dev/null || helm repo update ecommerce
    
    helm dependency update ./k8s/helm/ecommerce-microservices 2>/dev/null || true
    
    helm upgrade --install ecommerce ./k8s/helm/ecommerce-microservices \
        --namespace ecommerce-${environment} \
        --values ./k8s/helm/ecommerce-microservices/values/${environment}.yaml \
        --wait \
        --timeout 10m
    
    print_info "Microservicios desplegados en ecommerce-${environment}"
}

# Verificar deployment
verify_deployment() {
    print_header "Verificando deployment"
    
    local environment=${1:-dev}
    
    print_info "Verificando namespace ecommerce-${environment}..."
    kubectl get pods -n ecommerce-${environment}
    
    print_info "Servicios disponibles:"
    kubectl get svc -n ecommerce-${environment}
    
    print_info "Ingresses disponibles:"
    kubectl get ingress -n ecommerce-${environment}
}

# Mostrar información de acceso
show_access_info() {
    print_header "Información de acceso"
    
    print_info "Dashboard Grafana:"
    echo -e "${YELLOW}http://grafana.ecommerce.local:3000${NC}"
    echo "Usuario: admin"
    echo "Contraseña: admin123"
    
    print_info "Prometheus:"
    echo -e "${YELLOW}http://prometheus.ecommerce.local:9090${NC}"
    
    print_info "Jaeger:"
    echo -e "${YELLOW}http://jaeger.ecommerce.local:16686${NC}"
    
    print_info "Kibana (Logs):"
    echo -e "${YELLOW}http://kibana.ecommerce.local:5601${NC}"
    
    print_info "API Gateway:"
    echo -e "${YELLOW}https://api.ecommerce.local${NC}"
    
    print_info "Service Discovery (Eureka):"
    echo -e "${YELLOW}https://eureka.ecommerce.local${NC}"
    
    print_info "Cloud Config:"
    echo -e "${YELLOW}https://config.ecommerce.local${NC}"
}

# Función principal
main() {
    local environment=${1:-dev}
    local skip_infra=${2:-false}
    
    print_header "Inicializando Kubernetes para eCommerce Microservices"
    
    check_requirements
    
    if [ "$skip_infra" != "skip-infra" ]; then
        create_namespaces
        setup_infrastructure
        install_ingress_controller
        install_cert_manager
        configure_letsencrypt
        setup_storage
        install_monitoring
        install_logging
    fi
    
    deploy_microservices $environment
    verify_deployment $environment
    show_access_info
    
    print_header "¡Deployment completado exitosamente!"
}

# Manejo de argumentos
case "${1:-}" in
    dev|qa|prod)
        main "$1" "${2:-}"
        ;;
    help)
        echo "Uso: ./k8s-deploy.sh [dev|qa|prod] [skip-infra]"
        echo ""
        echo "Ejemplos:"
        echo "  ./k8s-deploy.sh dev              # Deploy a desarrollo"
        echo "  ./k8s-deploy.sh qa               # Deploy a QA"
        echo "  ./k8s-deploy.sh prod             # Deploy a producción"
        echo "  ./k8s-deploy.sh dev skip-infra   # Deploy solo microservicios"
        ;;
    *)
        main "dev"
        ;;
esac
