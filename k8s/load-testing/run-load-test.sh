#!/bin/bash

# Script de pruebas de carga con Locust
# Requiere: Python 3.7+, locust, requests

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
API_URL="${1:-http://localhost:8080}"
NUM_USERS="${2:-100}"
SPAWN_RATE="${3:-10}"
RUN_TIME="${4:-5m}"

echo "=========================================="
echo "eCommerce Microservices Load Test"
echo "=========================================="
echo "API URL: $API_URL"
echo "Number of Users: $NUM_USERS"
echo "Spawn Rate: $SPAWN_RATE users/sec"
echo "Run Time: $RUN_TIME"
echo "=========================================="
echo ""

# Instalar dependencias si no existen
if ! command -v locust &> /dev/null; then
    echo "Instalando Locust..."
    pip install locust>=2.0
fi

# Ejecutar test de carga
locust -f "$SCRIPT_DIR/locustfile.py" \
    --host="$API_URL" \
    --users=$NUM_USERS \
    --spawn-rate=$SPAWN_RATE \
    --run-time=$RUN_TIME \
    --csv=load-test-results \
    --html=load-test-report.html

echo ""
echo "=========================================="
echo "Test completado"
echo "Reportes generados:"
echo "  - load-test-results_stats.csv"
echo "  - load-test-report.html"
echo "=========================================="
