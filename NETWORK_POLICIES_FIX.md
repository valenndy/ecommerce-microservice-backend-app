# 🔧 SOLUCIÓN: Error YAML en NetworkPolicies

## ❌ Error Reportado

```
[INFO] Aplicando NetworkPolicies...
error: error parsing k8s/infrastructure/network-policies.yaml: 
error converting YAML to JSON: yaml: invalid map key: 
map[interface {}]interface {}{".Release.Namespace":interface {}(nil)}
```

---

## ✅ SOLUCIÓN APLICADA

### 1. **Problema Identificado**
El archivo `k8s/infrastructure/network-policies.yaml` contenía templating de Helm:
```yaml
namespace: {{ .Release.Namespace }}  ❌ Invalid YAML
```

Esto no es YAML válido cuando se intenta aplicar directamente con `kubectl`.

### 2. **Soluciones Implementadas**

#### ✅ Solución 1: YAML Puro en k8s/infrastructure/
- Removido todo templating de `k8s/infrastructure/network-policies.yaml`
- Ahora es YAML válido sin dependencias de Helm
- Propósito: **Referencia y documentación**

#### ✅ Solución 2: Template de Helm en k8s/helm/
- Creado archivo: `k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml`
- Contiene templating correcto: `{{ .Release.Namespace }}`
- Propósito: **Deployment automático con Helm**
- Incluye condicional: `{{- if .Values.networkPolicy.enabled }}`

#### ✅ Solución 3: Script Actualizado
- `k8s-deploy.sh` ya no intenta aplicar `network-policies.yaml` directamente
- Las políticas se crean automáticamente cuando ejecutas Helm

---

## 🚀 CÓMO USAR AHORA

### Opción 1: Despliegue Automático (RECOMENDADO)

```bash
# Ejecutar script (crea NetworkPolicies automáticamente)
./k8s-deploy.sh dev

# ✅ Helm deployment incluye NetworkPolicies
# ✅ Se aplican al namespace correcto (ecommerce-dev)
# ✅ Se actualizan dinámicamente si cambias values.yaml
```

### Opción 2: Despliegue Manual

```bash
# Crear namespaces
kubectl apply -f k8s/namespaces/namespaces.yaml

# Crear RBAC
kubectl apply -f k8s/security/rbac.yaml

# Crear Pod Security
kubectl apply -f k8s/security/pod-security.yaml

# Helm install (incluye NetworkPolicies)
helm install ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev

# ✅ NetworkPolicies se crean automáticamente
```

---

## 📂 Estructura de Archivos

```
k8s/
├── infrastructure/
│   ├── network-policies.yaml           ← YAML puro (referencia)
│   └── NETWORK_POLICIES_README.md      ← Documentación

k8s/helm/ecommerce-microservices/
├── values.yaml                          ← Incluye: networkPolicy.enabled: true
├── templates/
│   ├── networkpolicy.yaml              ← Template Helm (deployment)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
```

---

## ✅ Verificación

### Ver NetworkPolicies Creadas

```bash
# Después de ejecutar ./k8s-deploy.sh dev

# Listar
kubectl get networkpolicies -n ecommerce-dev

# Ver detalles
kubectl describe networkpolicy allow-from-api-gateway -n ecommerce-dev

# Ver en YAML
kubectl get networkpolicy allow-from-api-gateway -n ecommerce-dev -o yaml
```

### Esperado

```
NAME                                NAMESPACE
allow-from-api-gateway             ecommerce-dev
allow-from-ingress                 ecommerce-dev
allow-inter-service                ecommerce-dev
user-service-network-policy        ecommerce-dev
product-service-network-policy     ecommerce-dev
order-service-network-policy       ecommerce-dev
favourite-service-network-policy   ecommerce-dev
payment-service-network-policy     ecommerce-dev
shipping-service-network-policy    ecommerce-dev
infrastructure-services-network-policy ecommerce-dev
```

---

## 🔄 Flujo Correcto de Despliegue

```
./k8s-deploy.sh dev
│
├─ Verificar herramientas (kubectl, helm, docker) ✓
│
├─ Crear namespaces
│  └─ kubectl apply -f k8s/namespaces/namespaces.yaml ✓
│
├─ Configurar infraestructura
│  ├─ RBAC: kubectl apply -f k8s/security/rbac.yaml ✓
│  └─ Pod Security: kubectl apply -f k8s/security/pod-security.yaml ✓
│
├─ Instalar Ingress Controller (helm repo + helm install)
│
├─ Instalar cert-manager (helm repo + helm install)
│
├─ Configurar Let's Encrypt
│
├─ Persistencia (PVC, MySQL, etc.)
│
└─ **Helm install microservicios**
   └─ Incluye NetworkPolicies template ✓
      └─ Se crean en namespace ecommerce-dev ✓
         └─ Con templating Helm correcto ✓
```

---

## 💡 Conceptos Clave

### YAML Puro vs Template Helm

| Aspecto | YAML Puro | Template Helm |
|---------|-----------|---------------|
| Ubicación | `k8s/infrastructure/` | `k8s/helm/*/templates/` |
| Templating | ❌ No | ✅ Sí |
| Variables | ❌ Ninguna | ✅ {{ .Release.Namespace }} |
| Aplicación | ❌ Directamente (error) | ✅ Via Helm install |
| Namespace | ❌ No especificado | ✅ Dinámico |
| Propósito | 📖 Referencia | 🎯 Deployment |

### ¿Por Qué Dos Versiones?

1. **YAML Puro** (`k8s/infrastructure/network-policies.yaml`):
   - Documentación clara
   - Referencia para entender las políticas
   - Base para template Helm
   - SIN templating (YAML válido)

2. **Template Helm** (`k8s/helm/*/templates/networkpolicy.yaml`):
   - Deployment automático
   - Namespace dinámico
   - Parameterizable via values.yaml
   - CON templating Helm

---

## 🆘 Si Aún Tienes Problemas

### Problema: Aún sale error de YAML

**Causa**: Puede haber cached de la versión antigua

**Solución**:
```bash
# Limpiar
rm -rf ~/.helm/cache
helm repo update

# Reintentar
./k8s-deploy.sh dev
```

### Problema: NetworkPolicies no aparecen

**Causa**: `networkPolicy.enabled: false` en values.yaml

**Solución**:
```bash
# Verificar values
cat k8s/helm/ecommerce-microservices/values.yaml | grep -A2 networkPolicy

# Debe mostrar:
# networkPolicy:
#   enabled: true

# Redeploy
helm upgrade ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev
```

### Problema: Errores de conectividad entre pods

**Causa**: NetworkPolicies muy restrictivas (posible, pero menos probable)

**Solución temporal**:
```bash
# Deshabilitar temporalmente para testing
helm upgrade ecommerce \
  -f k8s/helm/ecommerce-microservices/values/dev.yaml \
  --set networkPolicy.enabled=false \
  k8s/helm/ecommerce-microservices \
  -n ecommerce-dev

# Si funciona, es problema de políticas
# Si no funciona, es otro problema
```

---

## 📚 Archivos Modificados/Creados

✅ **Modificados**:
- `k8s-deploy.sh` - No intenta aplicar network-policies.yaml directamente
- `k8s/infrastructure/network-policies.yaml` - YAML puro sin templating
- `k8s/helm/ecommerce-microservices/values.yaml` - Agregado networkPolicy config

✅ **Creados**:
- `k8s/helm/ecommerce-microservices/templates/networkpolicy.yaml` - Template Helm
- `k8s/infrastructure/NETWORK_POLICIES_README.md` - Documentación
- `k8s-verify.sh` - Script de verificación
- Este archivo (`NETWORK_POLICIES_FIX.md`) - Explicación de la solución

---

## 🎯 Próximos Pasos

1. ✅ Ejecutar: `./k8s-deploy.sh dev`
2. ✅ Verificar: `kubectl get networkpolicies -n ecommerce-dev`
3. ✅ Ver detalles: `kubectl describe networkpolicy allow-from-api-gateway -n ecommerce-dev`
4. ✅ Monitorear pods: `kubectl get pods -n ecommerce-dev`

---

**Versión**: 1.0  
**Fecha**: Nov 2025  
**Estado**: ✅ RESUELTO

