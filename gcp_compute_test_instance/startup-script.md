#!/bin/bash
# GCP startup script — runs on every boot.
# Writes the tester script and ensures the systemd service is running.
# No Python, pip, or external packages required — uses curl and dig only.
set -euo pipefail
exec >> /var/log/gcp-tester-startup.log 2>&1

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Startup script invoked"

mkdir -p /opt/gcp-tester

# ──────────────────────────────────────────────────────────────────────────────
# Write the tester script (overwrites on every boot so config changes apply)
# ──────────────────────────────────────────────────────────────────────────────
cat > /opt/gcp-tester/tester.sh << 'TESTEREOF'
#!/bin/bash
# Continuously tests GCP APIs (Compute, Storage) and DNS servers.
# Logs structured results to Cloud Logging via the REST API.
# Requires: curl (always present on RHEL 8), dig (bind-utils).
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────────────

# IP addresses of the DNS servers to query.
DNS_SERVERS=(
    # "10.0.0.1"
    # "10.0.0.2"
)

# Hostname to resolve against each DNS server above.
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

# Refreshes the global ACCESS_TOKEN from the attached service account.
# Called once per test cycle; tokens are valid for 1 hour.
refresh_token() {
    ACCESS_TOKEN=$(metadata "instance/service-accounts/default/token" \
        | sed 's/.*"access_token":"\([^"]*\)".*/\1/')
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

    # Sanitise detail for inline JSON: escape backslashes, then quotes,
    # then collapse newlines to a space.
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
test_compute_api() {
    local start http_code
    start=$(now_ms)
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://compute.googleapis.com/compute/v1/projects/${PROJECT_ID}/aggregated/instances?maxResults=10" \
        2>/dev/null || echo "000")
    log_result "compute_api" \
        "$([[ $http_code == 200 ]] && echo PASS || echo FAIL)" \
        $(( $(now_ms) - start )) \
        "HTTP ${http_code}"
}

test_storage_api() {
    local start http_code
    start=$(now_ms)
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://storage.googleapis.com/storage/v1/b?project=${PROJECT_ID}&maxResults=10" \
        2>/dev/null || echo "000")
    log_result "storage_api" \
        "$([[ $http_code == 200 ]] && echo PASS || echo FAIL)" \
        $(( $(now_ms) - start )) \
        "HTTP ${http_code}"
}

test_dns_server() {
    local server="$1" hostname="$2"
    local start output rc
    start=$(now_ms)
    output=$(dig +short +timeout=5 +tries=1 "@${server}" "${hostname}" A 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 && -n "$output" ]]; then
        log_result "dns_${server}" "PASS" $(( $(now_ms) - start )) \
            "${hostname} -> ${output//$'\n'/, }"
    else
        log_result "dns_${server}" "FAIL" $(( $(now_ms) - start )) \
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
    test_compute_api
    test_storage_api
    if [[ "$DIG_AVAILABLE" == "true" ]]; then
        for server in "${DNS_SERVERS[@]+"${DNS_SERVERS[@]}"}"; do
            test_dns_server "$server" "$DNS_LOOKUP_HOSTNAME"
        done
    fi
    sleep "$TEST_INTERVAL_SECONDS"
done
TESTEREOF

chmod +x /opt/gcp-tester/tester.sh

# ──────────────────────────────────────────────────────────────────────────────
# Write the systemd unit (overwrites on every boot)
# ──────────────────────────────────────────────────────────────────────────────
cat > /etc/systemd/system/gcp-tester.service << 'SVCEOF'
[Unit]
Description=GCP API and DNS Continuous Tester
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/gcp-tester/tester.sh
Restart=always
RestartSec=15
# Give the network stack 30 s on boot before the first run
ExecStartPre=/bin/sleep 30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=gcp-tester

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable gcp-tester.service

if systemctl is-active --quiet gcp-tester.service; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Restarting service (config may have changed)"
  systemctl restart gcp-tester.service
else
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting service"
  systemctl start gcp-tester.service
fi

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Setup complete"
systemctl status gcp-tester.service --no-pager || true
