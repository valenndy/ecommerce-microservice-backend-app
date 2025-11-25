#!/bin/bash

# Sync all updated Dockerfiles from Windows to WSL2

echo "Syncing Dockerfiles from Windows to WSL2..."

for dir in api-gateway cloud-config favourite-service order-service payment-service product-service proxy-client shipping-service user-service; do
  echo "Syncing $dir/Dockerfile..."
  rsync -av /mnt/c/Users/Andy/Documents/ecommerce-microservice-backend-app/$dir/Dockerfile ~/projects/ecommerce/$dir/
done

echo "All Dockerfiles synced!"
