#!/usr/bin/env bash
# Fattakse API Contract Verification Helper Script
# Usage: bash verify-contract.sh <ENDPOINT_PATH> [BASE_URL]
# Example: bash verify-contract.sh /api/v1/config http://localhost:8000

set -euo pipefail

ENDPOINT="${1:-/api/v1/config}"
BASE_URL="${2:-http://localhost:8000}"
TARGET_URL="${BASE_URL}${ENDPOINT}"

echo "=========================================================="
echo "Fattakse API Contract Verifier"
echo "Testing: ${TARGET_URL}"
echo "=========================================================="

# Test with Flutter Mobile Headers (Tobacco Suppression Check)
echo "1. Checking Flutter Mobile Request..."
RESPONSE_MOBILE=$(curl -s -H "X-Client-Type: flutter-mobile" -H "zoneId: [1]" "${TARGET_URL}")

if echo "${RESPONSE_MOBILE}" | grep -iq "tobacco\|cigarette\|paan corner\|gutkha"; then
  echo "❌ FAILED: Mobile response contains restricted tobacco terms! Violation of ADR-0009."
  exit 1
else
  echo "✅ PASSED: Mobile response is 100% tobacco-free."
fi

# Test Error Envelope
echo "2. Checking 404/Error Envelope Structure..."
ERROR_RESPONSE=$(curl -s "${BASE_URL}/api/v1/non-existent-route-contract-test")
if echo "${ERROR_RESPONSE}" | grep -q '"errors":\s*\['; then
  echo "✅ PASSED: Error response conforms to { errors: [...] } shape."
else
  echo "⚠️ WARNING: Error response does not conform to standard { errors: [{ code, message }] } structure."
  echo "Received: ${ERROR_RESPONSE}"
fi

echo "Contract check completed."
