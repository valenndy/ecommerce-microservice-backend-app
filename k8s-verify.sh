#!/bin/bash
# Script de verificación para el despliegue de Kubernetes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        VERIFICACIÓN DE DESPLIEGUE KUBERNETES              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Función para verificar recurso
check_resource() {
    local resource_type=$1
    local namespace=$2
    local name=$3
    
    if kubectl get $resource_type $name -n $namespace &> /dev/null; then
        echo -e "${GREEN}✓${NC} $resource_type/$name existe"
        return 0
    else
        echo -e "${RED}✗${NC} $resource_type/$name NO EXISTE"
        return 1
    fi
}

# Verificar namespaces
echo -e "${BLUE}[1/5] Verificando Namespaces...${NC}"
for ns in ecommerce-dev ecommerce-qa ecommerce-prod; do
    if kubectl get namespace $ns &> /dev/null; then
        echo -e "${GREEN}✓${NC} Namespace $ns existe"
    else
        echo -e "${RED}✗${NC} Namespace $ns NO EXISTE"
    fi
done
echo ""

# Verificar RBAC
echo -e "${BLUE}[2/5] Verificando RBAC...${NC}"
if kubectl get clusterrole ecommerce-config-reader &> /dev/null; then
    echo -e "${GREEN}✓${NC} ClusterRole ecommerce-config-reader existe"
else
    echo -e "${RED}✗${NC} ClusterRole ecommerce-config-reader NO EXISTE"
fi
echo ""

# Verificar Network Policies (solo si está en ecommerce-dev)
echo -e "${BLUE}[3/5] Verificando NetworkPolicies...${NC}"
if [ -n "$(kubectl get networkpolicies -n ecommerce-dev 2>/dev/null)" ]; then
    count=$(kubectl get networkpolicies -n ecommerce-dev --no-headers 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} $count NetworkPolicies encontradas en ecommerce-dev"
else
    echo -e "${YELLOW}⚠${NC} No hay NetworkPolicies en ecommerce-dev (se crearán con Helm)"
fi
echo ""

# Verificar Pods (si existen)
echo -e "${BLUE}[4/5] Verificando Pods en ecommerce-dev...${NC}"
if [ -n "$(kubectl get pods -n ecommerce-dev 2>/dev/null)" ]; then
    pods=$(kubectl get pods -n ecommerce-dev --no-headers 2>/dev/null | wc -l)
    running=$(kubectl get pods -n ecommerce-dev --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} $running/$pods pods corriendo en ecommerce-dev"
    
    # Listar pods
    echo -e "\n${BLUE}Pods:${NC}"
    kubectl get pods -n ecommerce-dev --no-headers 2>/dev/null | awk '{print "  " $1 " (" $3 ")"}'
else
    echo -e "${YELLOW}⚠${NC} No hay pods en ecommerce-dev (aún no desplegados)"
fi
echo ""

# Verificar Servicios (si existen)
echo -e "${BLUE}[5/5] Verificando Services en ecommerce-dev...${NC}"
if [ -n "$(kubectl get svc -n ecommerce-dev 2>/dev/null)" ]; then
    svcs=$(kubectl get svc -n ecommerce-dev --no-headers 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} $svcs servicios en ecommerce-dev"
    
    # Listar servicios
    echo -e "\n${BLUE}Servicios:${NC}"
    kubectl get svc -n ecommerce-dev --no-headers 2>/dev/null | awk '{print "  " $1 " (" $2 ")"}'
else
    echo -e "${YELLOW}⚠${NC} No hay servicios en ecommerce-dev (aún no desplegados)"
fi
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   VERIFICACIÓN COMPLETA                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Resumen
echo -e "${GREEN}✓ Estructura base verificada${NC}"
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Ejecutar deployment:"
echo "   ./k8s-deploy.sh dev"
echo ""
echo "2. Esperar a que pods estén ready:"
echo "   kubectl rollout status deployment -n ecommerce-dev --all"
echo ""
echo "3. Verificar nuevamente:"
echo "   bash k8s-verify.sh"
echo ""
