#!/bin/bash
# 🐧 SETUP SCRIPT PARA WSL2 (Ubuntu 22.04)
# Ejecutar desde WSL2: bash setup-wsl2.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     WSL2 KUBERNETES SETUP - ecommerce-microservices           ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ═════════════════════════════════════════════════════════════════════
# 1. VERIFICAR SISTEMA
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[1/8] Verificando sistema...${NC}"

if ! grep -q "microsoft" /proc/version &> /dev/null; then
    echo -e "${RED}Error: Este script debe ejecutarse en WSL2${NC}"
    exit 1
fi

if ! [ "$(lsb_release -rs)" = "22.04" ]; then
    echo -e "${YELLOW}Advertencia: Este script fue testeado en Ubuntu 22.04${NC}"
    echo "Tu versión: $(lsb_release -rs)"
fi

echo -e "${GREEN}✓ Sistema verificado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 2. ACTUALIZAR SISTEMA
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[2/8] Actualizando sistema...${NC}"

sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    curl \
    wget \
    git \
    jq \
    vim \
    htop \
    build-essential

echo -e "${GREEN}✓ Sistema actualizado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 3. INSTALAR DOCKER
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[3/8] Instalando Docker...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker ya está instalado: $(docker --version)${NC}"
else
    # Instalar Docker CLI (el daemon viene de Docker Desktop en Windows)
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER
    
    # Crear directorio de configuración
    mkdir -p ~/.docker/cli-plugins
    
    echo -e "${YELLOW}⚠️  Nota: Debes ejecutar 'newgrp docker' o reiniciar para que surta efecto${NC}"
fi

echo -e "${GREEN}✓ Docker instalado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 4. INSTALAR KUBECTL
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[4/8] Instalando kubectl...${NC}"

if command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}kubectl ya está instalado: $(kubectl version --client --short 2>/dev/null | grep Client || kubectl version --client --short)${NC}"
else
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

echo -e "${GREEN}✓ kubectl instalado$(kubectl version --client --short 2>/dev/null)${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 5. INSTALAR HELM
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[5/8] Instalando Helm...${NC}"

if command -v helm &> /dev/null; then
    echo -e "${YELLOW}Helm ya está instalado: $(helm version --short)${NC}"
else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo -e "${GREEN}✓ Helm instalado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 6. ELEGIR KUBERNETES DISTRIBUTION
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[6/8] Eligiendo Kubernetes distribution...${NC}"

PS3=$'\n¿Cuál Kubernetes quieres usar?\n1) Minikube (más heavy, pero recomendado)\n2) Kind (más ligero)\n3) Ambos\n4) Saltear\nOpción: '
options=("Minikube" "Kind" "Ambos" "Saltear")
select opt in "${options[@]}"
do
    case $opt in
        "Minikube")
            INSTALL_MINIKUBE=true
            break
            ;;
        "Kind")
            INSTALL_KIND=true
            break
            ;;
        "Ambos")
            INSTALL_MINIKUBE=true
            INSTALL_KIND=true
            break
            ;;
        "Saltear")
            break
            ;;
        *) echo "Opción inválida";;
    esac
done

# Instalar Minikube
if [ "$INSTALL_MINIKUBE" = true ]; then
    echo -e "\n${BLUE}Instalando Minikube...${NC}"
    
    if command -v minikube &> /dev/null; then
        echo -e "${YELLOW}Minikube ya está instalado: $(minikube version)${NC}"
    else
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    fi
    
    echo -e "${GREEN}✓ Minikube instalado${NC}"
fi

# Instalar Kind
if [ "$INSTALL_KIND" = true ]; then
    echo -e "\n${BLUE}Instalando Kind...${NC}"
    
    if command -v kind &> /dev/null; then
        echo -e "${YELLOW}Kind ya está instalado: $(kind version)${NC}"
    else
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    echo -e "${GREEN}✓ Kind instalado${NC}"
fi

echo -e "${GREEN}✓ Kubernetes distribution configurada${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 7. INICIAR CLUSTER KUBERNETES
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[7/8] Iniciando cluster Kubernetes...${NC}"

PS3=$'\n¿Quieres iniciar un cluster ahora?\n1) Sí, Minikube\n2) Sí, Kind\n3) No (lo haré después)\nOpción: '
options=("Minikube" "Kind" "Saltar")
select opt in "${options[@]}"
do
    case $opt in
        "Minikube")
            echo "Iniciando Minikube con Docker driver..."
            minikube start --driver=docker --cpus=4 --memory=8192
            minikube addons enable ingress metrics-server
            break
            ;;
        "Kind")
            echo "Creando cluster Kind..."
            kind create cluster --name ecommerce
            
            # Instalar NGINX Ingress Controller
            echo "Instalando NGINX Ingress Controller..."
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
            
            # Instalar metrics-server
            echo "Instalando metrics-server..."
            kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
            break
            ;;
        "Saltar")
            echo "OK, inicialo cuando estés listo:"
            echo "  Minikube: minikube start --driver=docker --cpus=4 --memory=8192"
            echo "  Kind:     kind create cluster --name ecommerce"
            break
            ;;
        *) echo "Opción inválida";;
    esac
done

echo -e "${GREEN}✓ Cluster preparado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# 8. CONFIGURAR PROYECTO
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[8/8] Configurando proyecto...${NC}"

# Copiar proyecto a home si está en /mnt/c
if [ -d "/mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app" ]; then
    echo "Copiando proyecto a home para mejor rendimiento..."
    mkdir -p ~/projects
    cp -r /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app ~/projects/ecommerce
    cd ~/projects/ecommerce
    echo -e "${YELLOW}Proyecto copiado a: ~/projects/ecommerce${NC}"
else
    cd $(pwd)
    echo -e "${YELLOW}Usando proyecto en: $(pwd)${NC}"
fi

# Hacer scripts ejecutables
chmod +x k8s-deploy.sh k8s-commands.sh run-load-test.sh setup-wsl2.sh 2>/dev/null

echo -e "${GREEN}✓ Proyecto configurado${NC}\n"

# ═════════════════════════════════════════════════════════════════════
# VERIFICACIÓN FINAL
# ═════════════════════════════════════════════════════════════════════

echo -e "${BLUE}Verificando instalaciones...${NC}\n"

echo "Docker:"
docker --version || echo "  ⚠️  No disponible"

echo "kubectl:"
kubectl version --client --short 2>/dev/null || kubectl version --client || echo "  ⚠️  No disponible"

echo "Helm:"
helm version --short || echo "  ⚠️  No disponible"

if command -v minikube &> /dev/null; then
    echo "Minikube:"
    minikube version
fi

if command -v kind &> /dev/null; then
    echo "Kind:"
    kind version
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         SETUP COMPLETADO! 🎉                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo "Próximos pasos:"
echo "1. Verifica el cluster:"
echo "   kubectl cluster-info"
echo "   kubectl get nodes"
echo ""
echo "2. Despliega el proyecto:"
echo "   cd $(pwd)"
echo "   source k8s-commands.sh"
echo "   ./k8s-deploy.sh dev"
echo ""
echo "3. Accede a los servicios:"
echo "   kubectl port-forward -n ecommerce-dev svc/grafana 3000:3000"
echo "   http://localhost:3000"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "   • Docker Desktop debe estar corriendo en Windows"
echo "   • Ejecuta 'newgrp docker' si tienes problemas con permisos"
echo "   • Para mejor rendimiento, copia el proyecto a WSL2 home"
echo ""
