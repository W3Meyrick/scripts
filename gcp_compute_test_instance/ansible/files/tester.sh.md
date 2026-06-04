#!/bin/bash
# Continuously tests GCP API forwarders (gcr.io) and DNS resolution
# via the system resolver (Cloud DNS → Unbound catch-all).
# Logs structured results to Cloud Logging via the REST API.
# Requires: curl (always present on RHEL 8), dig (bind-utils).
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────────────

# Hostname to resolve via the system resolver (Cloud DNS → Unbound catch-all).
DNS_LOOKUP_HOSTNAME="example.internal"

# Seconds between full test runs.
TEST_INTERVAL_SECONDS=60

# Cloud Logging log name (appears under logs/gcp-api-dns-tester in the console).
LOG_NAME="gcp-api-dns-tester"

# ──────────────────────────────────────────────────────────────────────────────
# Bootstrap — read identity from the GCE metadata server
# ──────────────────────────────────────────────────────────────────────────────
METADATA="http://metadata.google.internal/computeMetadata/v1"

metadata() {
    curl -sf -H "Metadata-Flavor: Google" "${METADATA}/${1}"
}

PROJECT_ID=$(metadata "project/project-id")
INSTANCE_NAME=$(metadata "instance/name")
ZONE=$(metadata "instance/zone" | sed 's|.*/||')

# Refreshes the global ACCESS_TOKEN using the gcloud SDK, which handles
# credential management and token caching for the attached service account.
refresh_token() {
    ACCESS_TOKEN=$(gcloud auth print-access-token)
}

# ──────────────────────────────────────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────────────────────────────────────
now_ms() { date +%s%3N; }

log_result() {
    local test_name="$1" result="$2" duration_ms="$3" detail="$4"
    local severity timestamp json

    [[ "$result" == "PASS" ]] && severity="INFO" || severity="ERROR"
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)

    detail="${detail//\\/\\\\}"
    detail="${detail//\"/\\\"}"
    detail="${detail//$'\n'/ }"

    json=$(printf \
        '{"entries":[{"logName":"projects/%s/logs/%s","resource":{"type":"gce_instance","labels":{"project_id":"%s","instance_id":"%s","zone":"%s"}},"severity":"%s","timestamp":"%s","jsonPayload":{"test":"%s","result":"%s","duration_ms":%d,"detail":"%s","instance":"%s"}}]}' \
        "$PROJECT_ID" "$LOG_NAME" \
        "$PROJECT_ID" "$INSTANCE_NAME" "$ZONE" \
        "$severity" "$timestamp" \
        "$test_name" "$result" "$duration_ms" "$detail" "$INSTANCE_NAME")

    if ! curl -sf -X POST \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$json" \
            "https://logging.googleapis.com/v2/entries:write" > /dev/null 2>&1; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING: failed to write log for ${test_name}" >&2
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────────────────────────────────────

# Tests the GCP API forwarders (transparent nginx-based proxies on the platform)
# via the gcr.io Docker Registry v2 ping endpoint.
test_gcr_api() {
    local start http_code
    start=$(now_ms)
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://gcr.io/v2/" \
        2>/dev/null || echo "000")
    log_result "gcr_api" \
        "$([[ $http_code == 200 ]] && echo PASS || echo FAIL)" \
        $(( $(now_ms) - start )) \
        "HTTP ${http_code}"
}

# Tests DNS resolution via the system resolver (Cloud DNS → Unbound catch-all).
# No server specified — exercises the full resolver chain as any workload would.
test_dns() {
    local start output rc
    start=$(now_ms)
    output=$(dig +short +timeout=5 +tries=1 "${DNS_LOOKUP_HOSTNAME}" A 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 && -n "$output" ]]; then
        log_result "dns" "PASS" $(( $(now_ms) - start )) \
            "${DNS_LOOKUP_HOSTNAME} -> ${output//$'\n'/, }"
    else
        log_result "dns" "FAIL" $(( $(now_ms) - start )) \
            "dig exit ${rc}: ${output}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main loop
# ──────────────────────────────────────────────────────────────────────────────
if ! command -v dig > /dev/null 2>&1; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING: 'dig' not found (install bind-utils) — DNS tests will be skipped" >&2
    DIG_AVAILABLE=false
else
    DIG_AVAILABLE=true
fi

refresh_token
log_result "tester_lifecycle" "PASS" 0 "tester started"

while true; do
    refresh_token
    test_gcr_api
    if [[ "$DIG_AVAILABLE" == "true" ]]; then
        test_dns
    fi
    sleep "$TEST_INTERVAL_SECONDS"
done
