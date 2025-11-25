# 🔒 NetworkPolicies - Documentación

## Archivos Relacionados

### 1. `k8s/infrastructure/network-policies.yaml`
**Propósito**: Referencia de las políticas de red en YAML puro

**Contenido**:
- 10 NetworkPolicies para diferentes servicios
- Plantillas YAML sin templating
- Útil para documentación y referencia

**Uso**:
- 📖 Documentación
- 🔍 Referencia rápida de políticas
- ✏️ Para modificar y aplicar manualmente si es necesario

**NOTA**: No se aplica directamente en `k8s-deploy.sh`

---

### 2. `k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml`
**Propósito**: Template de Helm para despliegue automatizado

**Contenido**:
- Las mismas 10 NetworkPolicies con templating de Helm
- Variables `{{ .Release.Namespace }}` para namespace dinámico
- Condicional `{{- if .Values.networkPolicy.enabled }}`

**Uso**:
- ✅ Se despliega automáticamente con Helm
- 🎯 Se aplica al namespace correcto automáticamente
- 🔧 Configurable via `values.yaml`

**NOTA**: Se aplica automáticamente cuando ejecutas:
```bash
./k8s-deploy.sh dev
helm install ecommerce ... k8s/helm/ecommerce-microservices -n ecommerce-dev
```

---

## 🎯 Flujo de Despliegue

```
./k8s-deploy.sh dev
    ↓
1. Crear namespaces
2. Aplicar RBAC (manual)
3. Aplicar Pod Security (manual)
4. Instalar Helm dependencies
5. Helm install (incluye NetworkPolicies template)
    ↓
✅ NetworkPolicies se crean automáticamente en namespace correcto
```

---

## 📋 Políticas de Red Implementadas

| Política | Función |
|----------|---------|
| `allow-from-api-gateway` | Permite tráfico desde API Gateway a todos los servicios |
| `allow-from-ingress` | Permite tráfico desde Ingress Controller al API Gateway |
| `allow-inter-service` | Permite comunicación entre servicios en el mismo namespace |
| `user-service-network-policy` | Acceso a User Service desde API Gateway, Proxy Client, Order Service |
| `product-service-network-policy` | Acceso a Product Service desde API Gateway, Favourite, Order |
| `order-service-network-policy` | Acceso a Order Service desde API Gateway, Proxy Client |
| `favourite-service-network-policy` | Acceso a Favourite desde API Gateway, Proxy Client |
| `payment-service-network-policy` | Acceso a Payment Service desde Order Service |
| `shipping-service-network-policy` | Acceso a Shipping Service desde Order Service |
| `infrastructure-services-network-policy` | Acceso a Service Discovery y Cloud Config desde todos |

---

## 🔧 Configuración

### En `values.yaml`

```yaml
networkPolicy:
  enabled: true          # Habilitar/deshabilitar
  policyTypes:
    - Ingress            # Controlar ingreso
    - Egress             # Controlar salida (futuro)
```

### Por Ambiente

Las políticas se aplican **igual** en todos los ambientes (dev, qa, prod) porque están definidas en el template de Helm y se aplican según el namespace.

---

## ✅ Verificación

### Listar NetworkPolicies

```bash
# Ver todas las políticas
kubectl get networkpolicies -n ecommerce-dev

# Ver detalles de una política
kubectl describe networkpolicy allow-from-api-gateway -n ecommerce-dev

# Ver en YAML
kubectl get networkpolicy allow-from-api-gateway -n ecommerce-dev -o yaml
```

### Prueba de Conectividad

```bash
# Ejecutar un pod de prueba
kubectl run test-pod --image=busybox --rm -it -n ecommerce-dev -- sh

# Dentro del pod, probar conectividad
wget -O- http://api-gateway:8080/health

# Si las políticas funcionan correctamente, deberías ver respuesta
# Si están muy restrictivas, verás timeout
```

---

## 🛠️ Modificar Políticas

### Opción 1: Editar YAML puro (referencia)

```bash
# Editar archivo de referencia
vim k8s/infrastructure/network-policies.yaml

# **NO** aplicar directamente:
# kubectl apply -f k8s/infrastructure/network-policies.yaml  ❌

# Mejor: copiar a template de Helm
cp k8s/infrastructure/network-policies.yaml \
   k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml
```

### Opción 2: Editar template de Helm (recomendado)

```bash
# Editar template (contiene templating correcto)
vim k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml

# Redeploy
helm upgrade ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev
```

### Opción 3: Deshabilitar temporalmente

```bash
# En values.yaml o como parámetro:
helm install ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  --set networkPolicy.enabled=false \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev
```

---

## 🚨 Troubleshooting

### Problema: Pods no pueden conectarse

**Síntoma**: Pods se quedan en `Pending` o no responden a requests

**Causas posibles**:
1. NetworkPolicies muy restrictivas
2. Ingress-nginx no en el namespace correcto
3. Pod labels no coinciden con selectores

**Solución**:

```bash
# 1. Verificar que NetworkPolicies están creadas
kubectl get networkpolicies -n ecommerce-dev

# 2. Ver detalles de una política
kubectl describe networkpolicy allow-from-api-gateway -n ecommerce-dev

# 3. Verificar labels de pods
kubectl get pods -n ecommerce-dev --show-labels

# 4. Temporalmente deshabilitar (para testing)
kubectl delete networkpolicies -n ecommerce-dev --all

# 5. Re-habilitar
helm upgrade ecommerce ... -n ecommerce-dev
```

### Problema: CNI plugin no soporta NetworkPolicy

**Síntoma**: NetworkPolicies se crean pero no funcionan

**Solución**: Instalar CNI que soporte NetworkPolicy:

```bash
# Para Minikube
minikube start --cni=calico

# Para Kind
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml

# Para cluster existente (requiere reinstalación)
# Ver: https://kubernetes.io/docs/concepts/cluster-administration/networking/
```

---

## 📚 Referencias

- [Kubernetes NetworkPolicy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico NetworkPolicy](https://projectcalico.docs.tigera.io/security/networkpolicy)
- [YAML Parsing Error Fix](https://www.kubernetes.io/docs/)

---

## ✨ Notas Importantes

1. **Helm template vs YAML puro**:
   - `k8s/infrastructure/` = Archivos YAML puros (referencia)
   - `k8s/helm/*/templates/` = Templates con Helm (deployment)

2. **Namespaces**:
   - Las políticas se crean automáticamente en el namespace de Helm
   - No necesitas especificar namespace manualmente

3. **CNI Requerido**:
   - Calico ✅
   - Cilium ✅
   - Flannel ❌
   - Weave ✅

4. **Testing**:
   - Siempre testa conectividad después de aplicar políticas
   - Mejor ir de restrictivo a permisivo que lo contrario

---

