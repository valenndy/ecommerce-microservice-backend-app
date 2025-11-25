# ⚡ QUICK START WSL2 (5 MINUTOS)

## 🔧 REQUISITOS

✅ WSL2 instalado (Ubuntu 22.04)  
✅ Docker Desktop en Windows con WSL2 habilitado  
✅ Internet  

---

## 🚀 EJECUCIÓN RÁPIDA

### 1. Abre WSL2 Terminal y copia el script

```bash
# Desde tu terminal WSL2, ejecuta:
cd /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app

# Hacer ejecutable
chmod +x setup-wsl2.sh

# Ejecutar (automático todo el setup)
bash setup-wsl2.sh
```

**Tiempo**: ~5 minutos (descarga + instalación)

### 2. Después del Setup

```bash
# Copiar proyecto a WSL2 home (mejor rendimiento)
cp -r ~/projects/ecommerce ~/ && cd ~/ecommerce

# Crear namespaces
kubectl apply -f k8s/namespaces/namespaces.yaml

# Desplegar
./k8s-deploy.sh dev
```

### 3. Acceder a Servicios

```bash
# Terminal 1: Grafana
kubectl port-forward -n ecommerce-dev svc/grafana 3000:3000

# Terminal 2: API
kubectl port-forward -n ecommerce-dev svc/api-gateway 8080:8080

# Terminal 3: Prometheus
kubectl port-forward -n ecommerce-dev svc/prometheus 9090:9090

# Abre en navegador:
# http://localhost:3000 (Grafana, admin/admin123)
# http://localhost:8080 (API Gateway)
# http://localhost:9090 (Prometheus)
```

---

## ⚙️ VERIFICACIÓN

```bash
# Cluster info
kubectl cluster-info

# Nodos
kubectl get nodes

# Pods en ecommerce-dev
kubectl get pods -n ecommerce-dev

# Servicios
kubectl get svc -n ecommerce-dev
```

---

## 🆘 PROBLEMAS COMUNES

| Problema | Solución |
|----------|----------|
| `docker: command not found` | Docker Desktop no está corriendo o no integrado con WSL2 |
| `minikube: command not found` | Ejecuta `bash setup-wsl2.sh` de nuevo |
| Pods en `Pending` | Aumenta memoria: `minikube start --memory=8192 --cpus=4` |
| `permission denied` | Ejecuta `newgrp docker` |
| Lento en `/mnt/c/` | Copia proyecto a home: `cp -r ~/projects/ecommerce ~/` |

---

## 📚 DOCUMENTACIÓN COMPLETA

Para detalles:
- `WSL2_UBUNTU_GUIDE.md` - Guía completa (problemas, tips, soluciones)
- `OPERATIONS_GUIDE.md` - Operaciones Kubernetes
- `k8s-commands.sh` - 60+ funciones útiles

---

## 🎯 OPCIÓN MÁS RÁPIDA (Una línea)

Si solo quieres ver que funciona:

```bash
# Copia proyecto + inicia cluster + despliega (automático)
bash setup-wsl2.sh
```

El script hace todo interactivamente.

---

**¡Listo!** Debería estar corriendo en <5 minutos. 🚀

