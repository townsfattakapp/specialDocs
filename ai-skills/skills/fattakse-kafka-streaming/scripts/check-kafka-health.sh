#!/usr/bin/env bash
# Redpanda / Kafka Cluster Health Check Script
# Usage: bash check-kafka-health.sh [BROKER_HOST_PORT]
# Example: bash check-kafka-health.sh localhost:9092

set -euo pipefail

BROKER="${1:-localhost:9092}"

echo "=========================================================="
echo "Fattakse Event Streaming Broker Health Check"
echo "Target Broker: ${BROKER}"
echo "=========================================================="

if command -v rpk &> /dev/null; then
  echo "1. Checking Redpanda cluster health using rpk..."
  rpk cluster health --brokers "${BROKER}" || true
  echo "2. Listing topics..."
  rpk topic list --brokers "${BROKER}" || true
elif command -v nc &> /dev/null; then
  HOST=$(echo "${BROKER}" | cut -d: -f1)
  PORT=$(echo "${BROKER}" | cut -d: -f2)
  echo "1. Checking TCP connectivity to ${HOST}:${PORT}..."
  if nc -z -v -w3 "${HOST}" "${PORT}" 2>&1; then
    echo "✅ Broker TCP port ${PORT} is open and accepting connections."
  else
    echo "❌ Cannot connect to ${HOST}:${PORT}. Ensure docker compose up redpanda is running."
    exit 1
  fi
else
  echo "Neither rpk nor nc available. Please ensure Docker container redpanda is running."
fi

echo "Health check complete."
