# ✅ DEPLOYMENT LISTO PARA EJECUTAR

## 🔧 Problemas Resueltos

### ❌ Error Original
```
[INFO] Aplicando NetworkPolicies...
error: error parsing k8s/infrastructure/network-policies.yaml: 
error converting YAML to JSON: yaml: invalid map key
```

### ✅ Solución Aplicada

1. **Removido templating de YAML puro** ✓
   - `k8s/infrastructure/network-policies.yaml` → YAML válido sin `{{ .Release.Namespace }}`

2. **Creado template Helm correcto** ✓
   - `k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml` → Con templating Helm

3. **Actualizado script de deploy** ✓
   - `k8s-deploy.sh` → Ya NO intenta aplicar network-policies.yaml directamente
   - Helm install → Incluye NetworkPolicies automáticamente

4. **Configurado en values.yaml** ✓
   - `networkPolicy.enabled: true` → Se aplica automáticamente

---

## 🚀 PRÓXIMOS PASOS EN WSL2

### 1. Verificar Cluster

```bash
cd ~/projects/ecommerce

# Ver que cluster está corriendo
kubectl cluster-info
kubectl get nodes
```

### 2. Crear Namespaces

```bash
# Crear los 4 namespaces (dev, qa, prod, infrastructure)
kubectl apply -f k8s/namespaces/namespaces.yaml

# Verificar
kubectl get ns | grep ecommerce
```

### 3. Ejecutar Deployment

```bash
# Desplegar a DESARROLLO
./k8s-deploy.sh dev

# Esto hará automáticamente:
# ✓ Verificar requisitos
# ✓ Crear infraestructura (RBAC, Pod Security)
# ✓ Instalar Ingress Controller
# ✓ Instalar cert-manager
# ✓ Helm install (incluye NetworkPolicies)
# ✓ Esperar a que pods estén ready
```

**Tiempo estimado**: 3-5 minutos

### 4. Verificar Despliegue

```bash
# Ver NetworkPolicies creadas
kubectl get networkpolicies -n ecommerce-dev

# Debe mostrar ~10 políticas (permite-from-api-gateway, etc.)

# Ver pods
kubectl get pods -n ecommerce-dev

# Ver servicios
kubectl get svc -n ecommerce-dev
```

### 5. Acceder a Servicios

```bash
# En terminal separada, ejecuta port-forwards:

# Grafana (admin/admin123)
kubectl port-forward -n ecommerce-dev svc/grafana 3000:3000 &

# API Gateway
kubectl port-forward -n ecommerce-dev svc/api-gateway 8080:8080 &

# Prometheus
kubectl port-forward -n ecommerce-dev svc/prometheus 9090:9090 &

# Kibana (logs)
kubectl port-forward -n ecommerce-dev svc/kibana 5601:5601 &

# Jaeger (tracing)
kubectl port-forward -n ecommerce-dev svc/jaeger 16686:16686 &
```

Luego desde Windows navegador:
- **Grafana**: http://localhost:3000
- **API**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Kibana**: http://localhost:5601
- **Jaeger**: http://localhost:16686

---

## 📋 Checklist

- [ ] WSL2 con Ubuntu 22.04 corriendo
- [ ] Docker Desktop corriendo en Windows
- [ ] Minikube o Kind cluster iniciado
- [ ] kubectl, helm instalados y funcionando
- [ ] Proyecto copiado a `~/projects/ecommerce`
- [ ] Ejecutar: `kubectl apply -f k8s/namespaces/namespaces.yaml`
- [ ] Ejecutar: `./k8s-deploy.sh dev`
- [ ] Verificar: `kubectl get networkpolicies -n ecommerce-dev`
- [ ] Verificar: `kubectl get pods -n ecommerce-dev`
- [ ] Port-forward a Grafana
- [ ] Acceder a http://localhost:3000

---

## 🎯 Una Vez Desplegado

### Ver Logs
```bash
# Logs de un servicio
kubectl logs -f deployment/api-gateway -n ecommerce-dev

# Logs de todos los pods
kubectl logs -f -n ecommerce-dev --all-containers=true --prefix=true
```

### Escalar Servicio
```bash
# Aumentar replicas manualmente
kubectl scale deployment api-gateway --replicas=3 -n ecommerce-dev

# Ver que HPA escala automáticamente si hay carga
kubectl get hpa -n ecommerce-dev
```

### Ejecutar Tests de Carga
```bash
bash k8s/load-testing/run-load-test.sh dev 10 5 1m
```

---

## 🆘 Si Algo Falla

### Error de YAML nuevamente
```bash
# Verificar que k8s-deploy.sh tiene la versión actualizada
grep "NetworkPolicies se desplegarán" k8s-deploy.sh

# Si no aparece, copiar nuevamente:
cp /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app/k8s-deploy.sh ~/projects/ecommerce/
```

### Pods no inicializan
```bash
# Ver detalles del pod
kubectl describe pod <POD_NAME> -n ecommerce-dev

# Ver logs
kubectl logs <POD_NAME> -n ecommerce-dev

# Aumentar memoria/CPU si es necesario
minikube stop
minikube start --cpus=8 --memory=16384
```

### Helm install falla
```bash
# Validar sintaxis del chart
helm lint k8s/helm/ecommerce-microservices

# Dry-run para ver qué se desplegaría
helm install ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev \
  --dry-run --debug
```

---

## 📚 Documentación

Lee para más detalles:
- `NETWORK_POLICIES_QUICK_FIX.md` - Resumen del error y solución
- `NETWORK_POLICIES_FIX.md` - Explicación completa
- `k8s/infrastructure/NETWORK_POLICIES_README.md` - Detalles de políticas
- `WSL2_QUICK_START.md` - Setup rápido en WSL2
- `WSL2_UBUNTU_GUIDE.md` - Guía completa de WSL2

---

## 🎉 ¡LISTO!

El despliegue está listo. Los cambios han sido aplicados en:
- ✅ `k8s/infrastructure/network-policies.yaml` - YAML puro (referencia)
- ✅ `k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml` - Template Helm (deployment)
- ✅ `k8s/helm/ecommerce-microservices/values.yaml` - Configuración de NetworkPolicy
- ✅ `k8s-deploy.sh` - Script actualizado

**Próximo paso**: Ejecuta `./k8s-deploy.sh dev` en WSL2 🚀

