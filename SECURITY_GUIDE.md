# Guía de Seguridad - e-Commerce Kubernetes

## Tabla de Contenidos
1. [Gestión de Secretos](#gestión-de-secretos)
2. [Control de Acceso (RBAC)](#control-de-acceso-rbac)
3. [Seguridad de Red](#seguridad-de-red)
4. [Pod Security](#pod-security)
5. [Encriptación de Datos](#encriptación-de-datos)
6. [Escaneo de Vulnerabilidades](#escaneo-de-vulnerabilidades)
7. [Mejores Prácticas](#mejores-prácticas)

## Gestión de Secretos

### Kubernetes Secrets (Desarrollo)

Para ambientes no críticos, usar Kubernetes Secrets nativos:

```bash
# Crear secret de credenciales de base de datos
kubectl create secret generic mysql-credentials \
  --from-literal=username=ecommerce \
  --from-literal=password=secure-password \
  -n ecommerce-dev

# Crear secret para JWT
kubectl create secret generic jwt-secret \
  --from-literal=secret=your-jwt-secret-key \
  -n ecommerce-dev

# Listar secrets
kubectl get secrets -n ecommerce-dev

# Ver contenido de un secret (base64 encoded)
kubectl get secret mysql-credentials -n ecommerce-dev -o yaml
```

### Sealed Secrets (Producción)

Para producción, usar Sealed Secrets para encriptar secrets en git:

```bash
# 1. Instalar Sealed Secrets controller
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets -n kube-system sealed-secrets/sealed-secrets

# 2. Obtener la clave pública
kubeseal -f /dev/null --print-public-cert > sealing-key.pem

# 3. Crear un secret normal
kubectl create secret generic mysql-credentials \
  --from-literal=username=ecommerce \
  --from-literal=password=secure-password \
  -n ecommerce-prod \
  --dry-run=client -o yaml > mysql-secret.yaml

# 4. Encriptarlo con kubeseal
kubeseal -f mysql-secret.yaml -w mysql-secret-sealed.yaml

# 5. Ahora mysql-secret-sealed.yaml es seguro guardar en git
git add mysql-secret-sealed.yaml

# 6. Aplicar en producción
kubectl apply -f mysql-secret-sealed.yaml
```

### External Secrets Operator (Para Vault/AWS Secrets Manager)

```yaml
# Configurar External Secret
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: ecommerce-prod
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      path: "secret/ecommerce"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "ecommerce-prod"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: mysql-credentials
  namespace: ecommerce-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: mysql-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: mysql-username
  - secretKey: password
    remoteRef:
      key: mysql-password
```

## Control de Acceso (RBAC)

### Principio de Menor Privilegio

Cada servicio tiene su propio ServiceAccount con permisos mínimos:

```yaml
# ServiceAccount para user-service
apiVersion: v1
kind: ServiceAccount
metadata:
  name: user-service
  namespace: ecommerce-prod

---
# Role con solo permisos necesarios
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: user-service-role
  namespace: ecommerce-prod
rules:
# Leer ConfigMaps de configuración
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["ecommerce-config"]
  verbs: ["get"]
# Leer Secrets
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["mysql-credentials", "jwt-secret"]
  verbs: ["get"]

---
# Binding del role al ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-service-rolebinding
  namespace: ecommerce-prod
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: user-service-role
subjects:
- kind: ServiceAccount
  name: user-service
  namespace: ecommerce-prod
```

### Auditoría de RBAC

```bash
# Ver todos los rolebindings en producción
kubectl get rolebindings -n ecommerce-prod

# Ver quién puede hacer qué
kubectl auth can-i get pods --as=system:serviceaccount:ecommerce-prod:user-service -n ecommerce-prod

# Verificar permisos en un secret específico
kubectl auth can-i get secret/mysql-credentials --as=system:serviceaccount:ecommerce-prod:user-service -n ecommerce-prod
```

## Seguridad de Red

### NetworkPolicies

Restringir tráfico entre pods:

```yaml
# Solo api-gateway puede acceder a user-service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-ingress
  namespace: ecommerce-prod
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    - podSelector:
        matchLabels:
          app: order-service
    ports:
    - protocol: TCP
      port: 8700

---
# Denegar todo el tráfico por defecto
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: ecommerce-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Verificar NetworkPolicies

```bash
# Listar todas las NetworkPolicies
kubectl get networkpolicies -n ecommerce-prod

# Ver detalles de una política
kubectl describe networkpolicy user-service-ingress -n ecommerce-prod

# Testear conectividad
kubectl run -it --rm debug --image=nicolaka/netshoot -n ecommerce-prod -- bash
# Dentro del pod:
# curl http://user-service:8700/actuator/health
```

## Pod Security

### Pod Security Standards

Configuración de seguridad estricta:

```yaml
# Namespace con restricciones de seguridad
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-prod
  labels:
    # Enforce = bloquea pods que no cumplan
    pod-security.kubernetes.io/enforce: restricted
    # Audit = registra violaciones
    pod-security.kubernetes.io/audit: restricted
    # Warn = muestra advertencias
    pod-security.kubernetes.io/warn: restricted

---
# Pod con configuración segura
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: ecommerce-prod
spec:
  # Contexto de seguridad a nivel de pod
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
    # Impedir escalada de privilegios
    allowPrivilegeEscalation: false
    # Solo capabilities mínimas
    capabilities:
      drop:
        - ALL
  
  containers:
  - name: app
    image: myapp:latest
    # Filesystem read-only
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      capabilities:
        drop:
          - ALL
    # Volúmenes temporales
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache
      mountPath: /var/cache
  
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache
    emptyDir: {}
```

### Restricción de recursos

```yaml
# ResourceQuota para limitar recursos por namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ecommerce-quota
  namespace: ecommerce-prod
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    limits.cpu: "200"
    limits.memory: "400Gi"
    pods: "500"

---
# LimitRange para pods individuales
apiVersion: v1
kind: LimitRange
metadata:
  name: ecommerce-limits
  namespace: ecommerce-prod
spec:
  limits:
  - type: Pod
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  - type: Container
    max:
      cpu: "1"
      memory: "1Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    defaultRequest:
      cpu: "250m"
      memory: "256Mi"
```

## Encriptación de Datos

### En Tránsito (TLS/HTTPS)

```yaml
# Certificate con Let's Encrypt
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-cert
  namespace: ecommerce-prod
spec:
  secretName: api-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: api.ecommerce.local
  dnsNames:
  - api.ecommerce.local
  - "*.ecommerce.local"

---
# Ingress con HTTPS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: ecommerce-prod
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.ecommerce.local
    secretName: api-tls
  rules:
  - host: api.ecommerce.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

### En Reposo (Base de Datos)

```bash
# Habilitar encriptación en base de datos MySQL
kubectl exec -it -n ecommerce-prod mysql-0 -- mysql \
  -uroot -p<password> \
  -e "ALTER TABLE orders ENCRYPTION='Y';"

# Verificar encriptación
kubectl exec -it -n ecommerce-prod mysql-0 -- mysql \
  -uroot -p<password> \
  -e "SELECT TABLE_NAME, TABLE_SCHEMA, CREATE_OPTIONS FROM information_schema.TABLES WHERE CREATE_OPTIONS LIKE '%ENCRYPTION%';"
```

### Backup Encriptado

```bash
# Backup de base de datos encriptado
kubectl exec -n ecommerce-prod mysql-0 -- mysqldump \
  -uroot -p$(kubectl get secret mysql-credentials -n ecommerce-prod \
  -o jsonpath='{.data.password}' | base64 -d) \
  --all-databases | openssl enc -aes-256-cbc -salt > backup.sql.enc

# Restaurar backup encriptado
openssl enc -d -aes-256-cbc -in backup.sql.enc | \
  kubectl exec -i -n ecommerce-prod mysql-0 -- mysql \
  -uroot -p$(kubectl get secret mysql-credentials -n ecommerce-prod \
  -o jsonpath='{.data.password}' | base64 -d)
```

## Escaneo de Vulnerabilidades

### Con Trivy

```bash
# Escanear una imagen
trivy image selimhorri/api-gateway-ecommerce-boot:0.1.0

# Generar reporte en JSON
trivy image --format json \
  --output report.json \
  selimhorri/api-gateway-ecommerce-boot:0.1.0

# Escanear todas las imágenes en cluster
for pod in $(kubectl get pods -n ecommerce-prod -o jsonpath='{.items[*].metadata.name}'); do
  image=$(kubectl get pod $pod -n ecommerce-prod -o jsonpath='{.spec.containers[0].image}')
  echo "Scanning: $image"
  trivy image "$image" --severity HIGH,CRITICAL
done
```

### Con Grype

```bash
# Escanear imagen
grype selimhorri/api-gateway-ecommerce-boot:0.1.0

# Generar tabla de formato
grype selimhorri/api-gateway-ecommerce-boot:0.1.0 -o table

# Solo vulnerabilidades críticas
grype selimhorri/api-gateway-ecommerce-boot:0.1.0 --fail-on critical
```

### Con Snyk

```bash
# Instalar Snyk CLI
npm install -g snyk

# Registrarse
snyk auth

# Testear imagen
snyk container test selimhorri/api-gateway-ecommerce-boot:0.1.0

# Monitorear vulnerabilidades continuas
snyk monitor
```

## Mejores Prácticas

### 1. Principio de Menor Privilegio
- ✅ Cada servicio con su own ServiceAccount
- ✅ Roles específicos con permisos mínimos
- ✅ No usar default ServiceAccount
- ✅ No usar cluster-admin excepto para setup

### 2. Gestión de Secretos
- ✅ Usar Sealed Secrets en producción
- ✅ Rotar secretos cada 90 días
- ✅ No commitear secretos en git
- ✅ Usar External Secrets para Vault

### 3. Seguridad de Red
- ✅ Implementar NetworkPolicies restrictivas
- ✅ Default deny policy
- ✅ Whitelist explícito de comunicaciones
- ✅ TLS en todas las conexiones

### 4. Pod Security
- ✅ Contenedores non-root
- ✅ Filesystem read-only cuando sea posible
- ✅ DROP ALL capabilities
- ✅ Restrict syscalls (seccomp)

### 5. Imágenes Seguras
- ✅ Base images minimalistas (alpine, distroless)
- ✅ No root user en imágenes
- ✅ Escanear vulnerabilidades antes de push
- ✅ Usar image signatures (cosign)

### 6. Audit y Logging
- ✅ Habilitar API server auditing
- ✅ Monitorear eventos de RBAC
- ✅ Logs centralizados (ELK Stack)
- ✅ Alertas en eventos sospechosos

### 7. Updates de Seguridad
- ✅ Monitorear CVEs de dependencias
- ✅ Patch kubernetes regularmente
- ✅ Actualizar imágenes base
- ✅ Automated security updates en no-prod

---

**Última revisión**: 2024
**Responsable**: Security Team
