#!/bin/bash
# Workstation script: tests the GCP API proxy for a fixed window.
# Run this on your workstation during the DR test window alongside the VM tester.
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - The API proxy configured in gcloud, e.g.:
#       gcloud config set proxy/type http
#       gcloud config set proxy/address YOUR_PROXY_HOST
#       gcloud config set proxy/port YOUR_PROXY_PORT
#     Or via environment variables: HTTPS_PROXY=http://host:port
#
# Results are written to a local .jsonl file and optionally to Cloud Logging.
# The log format matches the VM tester so both can be queried together for the report.
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — fill these in before running
# ──────────────────────────────────────────────────────────────────────────────
PROJECT_ID="YOUR_PROJECT_ID"

# How long to run (minutes) and how often to run each test cycle (seconds).
TEST_DURATION_MINUTES=60
TEST_INTERVAL_SECONDS=60

# Set to "true" to also write results to Cloud Logging (requires the
# authenticated gcloud user to have roles/logging.logWriter on the project).
# Set to "false" to write to the local log file only.
USE_CLOUD_LOGGING="true"
# ──────────────────────────────────────────────────────────────────────────────

LOG_NAME="gcp-api-proxy-test"
LOG_FILE="api-proxy-test-$(date +%Y%m%dT%H%M%S).jsonl"
SOURCE="workstation-$(hostname -s)"

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
        '{"timestamp":"%s","test":"%s","result":"%s","duration_ms":%d,"detail":"%s","source":"%s"}' \
        "$timestamp" "$test_name" "$result" "$duration_ms" "$detail" "$SOURCE")

    echo "$json" | tee -a "$LOG_FILE"

    if [[ "$USE_CLOUD_LOGGING" == "true" ]]; then
        if ! gcloud logging write "$LOG_NAME" "$json" \
                --payload-type=json \
                --severity="$severity" \
                --project="$PROJECT_ID" 2>/dev/null; then
            echo "  WARNING: Cloud Logging write failed for ${test_name} — result saved to ${LOG_FILE}" >&2
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────────────────────────────────────

test_compute_instances_list() {
    local start output rc count
    start=$(now_ms)
    output=$(gcloud compute instances list \
        --project="$PROJECT_ID" \
        --limit=10 \
        --format="value(name)" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        count=$(echo "$output" | grep -c . || true)
        log_result "compute_instances_list" "PASS" $(( $(now_ms) - start )) \
            "listed ${count} instances"
    else
        log_result "compute_instances_list" "FAIL" $(( $(now_ms) - start )) \
            "$output"
    fi
}

test_projects_describe() {
    local start output rc state
    start=$(now_ms)
    output=$(gcloud projects describe "$PROJECT_ID" \
        --format="value(lifecycleState)" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        state=$(echo "$output" | tr -d '[:space:]')
        log_result "projects_describe" "PASS" $(( $(now_ms) - start )) \
            "project lifecycleState: ${state}"
    else
        log_result "projects_describe" "FAIL" $(( $(now_ms) - start )) \
            "$output"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
echo "========================================================"
echo "  GCP API Proxy Test"
echo "  Project  : ${PROJECT_ID}"
echo "  Duration : ${TEST_DURATION_MINUTES} minutes"
echo "  Interval : ${TEST_INTERVAL_SECONDS} seconds"
echo "  Log file : ${LOG_FILE}"
echo "  Cloud Logging: ${USE_CLOUD_LOGGING} (log: ${LOG_NAME})"
echo "========================================================"
echo ""

log_result "proxy_test_lifecycle" "PASS" 0 "proxy test started on ${SOURCE}"

END_EPOCH=$(( $(date +%s) + TEST_DURATION_MINUTES * 60 ))

while [[ $(date +%s) -lt $END_EPOCH ]]; do
    test_compute_instances_list
    test_projects_describe

    REMAINING=$(( END_EPOCH - $(date +%s) ))
    [[ $REMAINING -le 0 ]] && break
    SLEEP=$(( REMAINING < TEST_INTERVAL_SECONDS ? REMAINING : TEST_INTERVAL_SECONDS ))
    sleep "$SLEEP"
done

log_result "proxy_test_lifecycle" "PASS" 0 "proxy test completed on ${SOURCE}"

echo ""
echo "========================================================"
echo "  Test complete."
echo "  Local results : ${LOG_FILE}"
if [[ "$USE_CLOUD_LOGGING" == "true" ]]; then
    echo ""
    echo "  Query Cloud Logging:"
    echo "    gcloud logging read \\"
    echo "      'logName=\"projects/${PROJECT_ID}/logs/${LOG_NAME}\"' \\"
    echo "      --project=${PROJECT_ID} --order=asc"
fi
echo "========================================================"
