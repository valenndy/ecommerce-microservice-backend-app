#!/bin/bash

# Build all microservices Docker images
# Usage: ./build-all-images.sh [tag]
# Default tag: latest

set -e

TAG="${1:-latest}"
REGISTRY="${2:-ecommerce}"

# Array of services to build
SERVICES=(
    "service-discovery"
    "cloud-config"
    "api-gateway"
    "proxy-client"
    "user-service"
    "product-service"
    "favourite-service"
    "order-service"
    "payment-service"
    "shipping-service"
)

echo "=========================================="
echo "Building Docker Images"
echo "=========================================="
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "Services to build: ${#SERVICES[@]}"
echo ""

for service in "${SERVICES[@]}"; do
    echo "Building $service..."
    cd "$(dirname "$0")/$service"
    
    if [ ! -f "Dockerfile" ]; then
        echo "  ❌ Dockerfile not found in $service"
        continue
    fi
    
    docker build \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
        -t "$REGISTRY/$service:$TAG" \
        .
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Built $REGISTRY/$service:$TAG"
    else
        echo "  ❌ Failed to build $service"
        exit 1
    fi
    echo ""
done

echo "=========================================="
echo "All images built successfully!"
echo "=========================================="
echo ""
echo "To push images to registry:"
echo "  docker tag ecommerce/<service>:$TAG <registry>/ecommerce/<service>:$TAG"
echo "  docker push <registry>/ecommerce/<service>:$TAG"
echo ""
echo "Current images:"
docker images | grep "^ecommerce/" | awk '{print "  "$1":"$2}'
