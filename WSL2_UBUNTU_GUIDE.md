# 🐧 GUÍA COMPLETA: WSL2 (UBUNTU 22.04) + KUBERNETES

## ¿Por Qué WSL2 es Excelente para Kubernetes?

✅ Rendimiento nativo de Linux  
✅ Integración perfecta con Docker Desktop  
✅ Menos recursos que VirtualBox/Hyper-V  
✅ Acceso a archivos Windows (`/mnt/c/`)  
✅ Terminal moderna con PowerShell/WSL  

---

## 📋 PASO 1: PREPARACIÓN EN WSL2

### Actualizar Sistema

```bash
# Abre WSL2 Terminal y ejecuta:
sudo apt update && sudo apt upgrade -y
```

### Instalar Herramientas Básicas

```bash
sudo apt install -y \
    curl \
    wget \
    git \
    jq \
    vim \
    htop \
    build-essential
```

---

## 🐳 PASO 2: CONFIGURAR DOCKER

### Opción A: Docker Desktop + WSL2 (RECOMENDADO)

**En Windows:**
1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Abre Docker Desktop → Settings → Resources → WSL Integration
3. Habilita tu distribución Ubuntu-22.04

**En WSL2:**
```bash
# Solo necesitas Docker CLI (Docker Desktop proporciona el daemon)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambio inmediatamente
newgrp docker

# Verificar
docker ps
```

### Opción B: Docker Daemon Nativo en WSL2

Si prefieres daemon nativo sin Docker Desktop:

```bash
# Instalar Docker (incluye daemon)
sudo apt install -y docker.io

# Iniciar servicio
sudo service docker start

# Agregar usuario
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker ps
```

**Nota**: Debes ejecutar `sudo service docker start` cada vez que inicies WSL2 o agregarlo a `.bashrc`

---

## ☸️ PASO 3: INSTALAR KUBERNETES

### OPCIÓN A: Minikube (Recomendado para Aprender)

#### Instalación

```bash
# Descargar última versión
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verificar
minikube version
```

#### Iniciar Cluster

```bash
# Con Docker driver (RECOMENDADO en WSL2)
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=40g

# Esperar a que esté ready (2-3 minutos)
kubectl cluster-info
```

#### Habilitar Addons

```bash
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
```

#### Acceder a Dashboard (Opcional)

```bash
# En terminal 1:
minikube dashboard

# En terminal 2: Accede a localhost:8001 (aproximadamente)
```

---

### OPCIÓN B: Kind (Más Ligero - Recomendado para CI/CD)

#### Instalación

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verificar
kind version
```

#### Crear Cluster

```bash
# Configuración simple
kind create cluster --name ecommerce

# O con configuración avanzada
kind create cluster --name ecommerce --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8761
    hostPort: 8761
    protocol: TCP
  - containerPort: 3000
    hostPort: 3000
    protocol: TCP
  - containerPort: 9090
    hostPort: 9090
    protocol: TCP
  - containerPort: 5601
    hostPort: 5601
    protocol: TCP
  - containerPort: 16686
    hostPort: 16686
    protocol: TCP
EOF

# Verificar
kubectl cluster-info
```

#### Instalar Ingress Controller

```bash
# NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Esperar a que esté ready
kubectl wait --namespace ingress-nginx --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller --timeout=120s
```

#### Instalar Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### Listar Clusters

```bash
kind get clusters
```

#### Eliminar Cluster

```bash
kind delete cluster --name ecommerce
```

---

## 📦 PASO 4: INSTALAR KUBECTL Y HELM

### kubectl

```bash
# Descargar
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalar
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar
kubectl version --client
```

### Helm 3

```bash
# Usar script oficial
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar
helm version
```

---

## 📂 PASO 5: PREPARAR PROYECTO

### Opción A: Copiar a WSL2 Home (MEJOR RENDIMIENTO)

Los archivos en `/mnt/c/` son más lentos. Es mejor copiar al home de WSL2:

```bash
# Crear directorio de proyectos
mkdir -p ~/projects

# Copiar proyecto
cp -r /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app ~/projects/ecommerce

# Navegar
cd ~/projects/ecommerce

# Hacer scripts ejecutables
chmod +x k8s-deploy.sh k8s-commands.sh run-load-test.sh
```

### Opción B: Usar Directamente de Windows

```bash
# Navegar (más lento, pero funciona)
cd /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app

# Hacer scripts ejecutables
chmod +x k8s-deploy.sh k8s-commands.sh run-load-test.sh
```

---

## 🚀 PASO 6: DESPLEGAR PROYECTO

### Verificar Cluster

```bash
# Debe mostrar: Running
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Ver estado de pod
kubectl get pods -A
```

### Crear Namespaces

```bash
# Aplicar configuración
kubectl apply -f k8s/namespaces/namespaces.yaml

# Verificar
kubectl get namespaces
```

### Desplegar con Helm

```bash
# Para Desarrollo
helm install ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev

# Esperar a que estén ready
kubectl rollout status deployment -n ecommerce-dev --all
```

### Verificar Despliegue

```bash
# Ver pods
kubectl get pods -n ecommerce-dev

# Ver servicios
kubectl get svc -n ecommerce-dev

# Ver logs de un servicio
kubectl logs -f deployment/api-gateway -n ecommerce-dev
```

---

## 🔌 PASO 7: ACCEDER A SERVICIOS

### Opción A: Port-Forward (Simple)

```bash
# API Gateway
kubectl port-forward -n ecommerce-dev svc/api-gateway 8080:8080 &

# Grafana
kubectl port-forward -n ecommerce-dev svc/grafana 3000:3000 &

# Prometheus
kubectl port-forward -n ecommerce-dev svc/prometheus 9090:9090 &

# Kibana
kubectl port-forward -n ecommerce-dev svc/kibana 5601:5601 &

# Jaeger
kubectl port-forward -n ecommerce-dev svc/jaeger 16686:16686 &
```

Luego accede desde Windows:
- API: http://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Kibana: http://localhost:5601
- Jaeger: http://localhost:16686

### Opción B: Configurar /etc/hosts (Para Dominio)

```bash
# Desde WSL2, obtener IP
minikube ip  # o: kubectl get svc -A

# En Windows (como Admin):
# Editar: C:\Windows\System32\drivers\etc\hosts
# Agregar:
192.168.49.2 api.ecommerce.local
192.168.49.2 grafana.ecommerce.local
192.168.49.2 prometheus.ecommerce.local
192.168.49.2 kibana.ecommerce.local
192.168.49.2 jaeger.ecommerce.local
```

---

## 🧪 PASO 8: EJECUTAR TESTS DE CARGA

### Con Locust

```bash
# Ejecutar tests
bash k8s/load-testing/run-load-test.sh dev 10 5 1m

# Ver resultados
kubectl logs -f -n ecommerce-dev deployment/locust-master
```

### Con JMeter

```bash
# Ejecutar tests
kubectl apply -f k8s/load-testing/jmeter-config.yaml

# Ver logs
kubectl logs -f -n ecommerce-dev job/jmeter-test
```

---

## 🆘 TROUBLESHOOTING PARA WSL2

### Problema: Docker no funciona

**Síntoma**: `docker ps` retorna error de conexión

**Solución**:
```bash
# Si usas Docker Desktop + WSL2:
# Verifica que Docker Desktop esté corriendo

# Si usas daemon nativo:
sudo service docker start

# O agregalo a ~/.bashrc:
echo 'sudo service docker start' >> ~/.bashrc

# Agregar usuario al grupo
sudo usermod -aG docker $USER
newgrp docker
```

### Problema: Minikube no inicia

**Síntoma**: `minikube start` se queda esperando

**Solución**:
```bash
# Detener cualquier instancia anterior
minikube stop
minikube delete

# Iniciar con más detalles
minikube start --driver=docker --v=3

# Si sigue fallando, verifica Docker:
docker ps
```

### Problema: Memoria/CPU insuficiente

**Síntoma**: Pods en `Pending` o `OOMKilled`

**Solución**:
```bash
# Aumentar recursos en Minikube
minikube stop
minikube start --cpus=8 --memory=16384

# O cambiar en Kind (requiere recrear):
kind delete cluster --name ecommerce
kind create cluster --name ecommerce  # con más recursos en nodo

# Verificar recursos actuales
kubectl top nodes
kubectl top pods -A
```

### Problema: Permiso denegado en kubectl

**Síntoma**: `error: Unable to connect to the server`

**Solución**:
```bash
# Reconstruir kubeconfig
rm ~/.kube/config
minikube config set profile minikube
minikube start
```

### Problema: WSL2 está lento

**Síntoma**: Operaciones toman mucho tiempo

**Solución**:
```bash
# Usar home de WSL2 en vez de /mnt/c/
# (copia el proyecto a ~/projects)

# Limitar recursos de WSL2 en ~/.wslconfig:
# [wsl2]
# memory=8GB
# processors=4
# swap=2GB

# Reiniciar WSL2
wsl --shutdown
```

### Problema: Conexión entre Windows y WSL2 es lenta

**Solución**:
```bash
# Usar IP de Minikube/Kind en vez de localhost
# Desde WSL2:
minikube ip  # ej: 192.168.49.2

# Desde Windows, accede a: http://192.168.49.2:3000
```

---

## ✨ TIPS PARA WSL2

### 1. Agregar a ~/.bashrc

```bash
cat >> ~/.bashrc <<'EOF'
# Docker daemon (si no usas Docker Desktop)
sudo service docker start &>/dev/null

# Alias útiles
alias k=kubectl
alias h=helm
alias d=docker
alias mm=minikube

# Funciones útiles
klog() {
    kubectl logs -f deployment/$1 -n ecommerce-dev
}

ksvc() {
    kubectl port-forward -n ecommerce-dev svc/$1 $2:$2
}

krun() {
    kubectl exec -it -n ecommerce-dev $(kubectl get pod -n ecommerce-dev -l app=$1 -o jsonpath='{.items[0].metadata.name}') -- bash
}
EOF

source ~/.bashrc
```

### 2. Configurar ~/.bashrc para Kubernetes

```bash
# Agregar completar comandos
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source <(helm completion bash)' >> ~/.bashrc

source ~/.bashrc
```

### 3. Configurar VS Code para Conectarse a WSL2

```bash
# En VS Code:
# 1. Instalar extensión "Remote - WSL"
# 2. Click "Remote Explorer" en lado izquierdo
# 3. Seleccionar Ubuntu-22.04
# 4. Click en carpeta del proyecto
# 5. VS Code abrirá en WSL2

# Comandos útiles en VS Code terminal:
code .  # Abre VS Code en carpeta actual
```

### 4. Configurar Git en WSL2

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
git config --global core.autocrlf input  # Importante para CRLF
```

---

## 📊 COMPARACIÓN: Minikube vs Kind

| Feature | Minikube | Kind |
|---------|----------|------|
| Peso | 500MB VM | Contenedor ligero |
| Velocidad inicio | 2-3 min | 30 seg |
| Dashboard | Sí (built-in) | No |
| Ingress | Sí | Necesita manual |
| Storage local | Sí | Sí |
| Escalabilidad | 1 nodo | Múltiples nodos |
| Recomendado para | Desarrollo local | CI/CD, testing |

**Mi recomendación para WSL2**: Usar **Kind** por su ligereza, o **Minikube** si necesitas dashboard.

---

## 🎯 SCRIPT RÁPIDO DE SETUP

Para automatizar todo:

```bash
# 1. Descargar script
curl -O https://raw.githubusercontent.com/tu-repo/setup-wsl2.sh

# 2. Ejecutar
bash setup-wsl2.sh

# 3. Seguir instrucciones interactivas
```

El script `setup-wsl2.sh` incluido en el proyecto hace todo esto automáticamente.

---

## ✅ CHECKLIST FINAL

- [ ] WSL2 actualizado (`wsl --update`)
- [ ] Docker Desktop instalado y corriendo en Windows
- [ ] Docker integrado con WSL2 en Docker Desktop settings
- [ ] Docker funciona en WSL2 (`docker ps`)
- [ ] kubectl instalado (`kubectl version --client`)
- [ ] Helm instalado (`helm version`)
- [ ] Minikube o Kind instalado
- [ ] Cluster iniciado (`kubectl cluster-info`)
- [ ] Proyecto copiado a ~/projects/ecommerce
- [ ] Namespaces creados (`kubectl get ns`)
- [ ] Helm deployment exitoso (`kubectl get pods -n ecommerce-dev`)
- [ ] Servicios accesibles (port-forward funcionando)

---

## 🚀 PRÓXIMOS PASOS

1. Ejecuta `bash setup-wsl2.sh` para automatizar setup
2. Inicia cluster: `minikube start --driver=docker --cpus=4 --memory=8192`
3. Despliega proyecto: `./k8s-deploy.sh dev`
4. Accede a Grafana: `kubectl port-forward -n ecommerce-dev svc/grafana 3000:3000`
5. Abre navegador: http://localhost:3000

---

**¿Tienes algún problema?** Revisa la sección Troubleshooting o contacta con el equipo DevOps.

