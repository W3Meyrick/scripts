```bash
fetch_metadata() {
    local path="$1"
    local regex="$2"
    local retries="${3:-$DEFAULT_RETRIES}"
    local backoff="$INITIAL_BACKOFF"
    local attempt=1
    local response http_code value

    local tmpfile
    tmpfile=$(mktemp) || return 1

    while (( attempt <= retries )); do
        http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" -H "$HEADER" "${METADATA_URL}${path}" || true)
        value=$(<"$tmpfile")

        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            if [[ "$value" =~ $regex ]]; then
                rm -f "$tmpfile"
                echo "$value"
                return 0
            else
                log_warn "Invalid format for $path (value: '$value') on attempt $attempt"
            fi
        else
            log_warn "HTTP $http_code from $path (attempt $attempt)"
        fi

        sleep "$backoff"
        backoff=$(( backoff * 2 ))
        ((attempt++))
    done

    rm -f "$tmpfile"
    log_error "Failed to get valid metadata from $path after $retries attempts"
    return 1
}


SUBNET_URI=$(fetch_metadata "/instance/network-interfaces/0/subnetwork" '^projects/[0-9]+/regions/[a-z0-9\-]+/subnetworks/[a-z][-a-z0-9]{0,62}[a-z0-9]$') || exit 1
SUBNET_NAME="${SUBNET_URI##*/}"

```


```bash
#!/bin/bash

set -euo pipefail

METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
HEADER="Metadata-Flavor: Google"
DEFAULT_RETRIES=5
INITIAL_BACKOFF=1

log_info()  { logger -t gcp-metadata-init "INFO: $*"; }
log_warn()  { logger -t gcp-metadata-init "WARN: $*"; }
log_error() { logger -t gcp-metadata-init "ERROR: $*"; }

# Fetch with retries, timeouts, regex validation
fetch_metadata() {
    local path="$1"
    local regex="$2"
    local retries="${3:-$DEFAULT_RETRIES}"
    local backoff="$INITIAL_BACKOFF"
    local attempt=1
    local tmpfile value http_code

    tmpfile=$(mktemp) || return 1

    while (( attempt <= retries )); do
        http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
            --connect-timeout 2 --max-time 5 \
            -H "$HEADER" "${METADATA_URL}${path}" || true)

        value=$(<"$tmpfile")

        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            if [[ "$value" =~ $regex ]]; then
                rm -f "$tmpfile"
                echo "$value"
                return 0
            else
                log_warn "Invalid format for $path: '$value' (attempt $attempt)"
            fi
        else
            log_warn "HTTP $http_code for $path (attempt $attempt)"
        fi

        sleep "$backoff"
        backoff=$(( backoff * 2 ))
        ((attempt++))
    done

    rm -f "$tmpfile"
    log_error "Failed to retrieve valid metadata from $path after $retries attempts"
    return 1
}

# Metadata initialization logic
init_metadata_variables() {
    log_info "Initializing GCP metadata..."

    INSTANCE_ID=$(fetch_metadata "/instance/id" '^[0-9]{10,20}$') || exit 1
    PROJECT_ID=$(fetch_metadata "/project/project-id" '^[a-z][a-z0-9\-]{4,61}[a-z0-9]$') || exit 1
    HOSTNAME=$(fetch_metadata "/instance/hostname" '^[a-z0-9\-]+\.c\.[a-z0-9\-]+\.internal$') || exit 1

    ZONE_URI=$(fetch_metadata "/instance/zone" '^projects/[0-9]+/zones/[a-z0-9\-]+$') || exit 1
    ZONE="${ZONE_URI##*/}"

    NETWORK_URI=$(fetch_metadata "/instance/network-interfaces/0/network" '^projects/[0-9]+/networks/[a-z]([-a-z0-9]{0,61}[a-z0-9])?$') || exit 1
    NETWORK_NAME="${NETWORK_URI##*/}"

    NIC0_IP=$(fetch_metadata "/instance/network-interfaces/0/ip" '^([0-9]{1,3}\.){3}[0-9]{1,3}$') || exit 1

    NIC0_GATEWAY=$(fetch_metadata "/instance/network-interfaces/0/gateway" '^([0-9]{1,3}\.){3}[0-9]{1,3}$') || exit 1

    NIC_COUNT=$(fetch_metadata "/instance/network-interfaces/" '^[0-9]+$') || exit 1

    export INSTANCE_ID PROJECT_ID HOSTNAME ZONE NETWORK_NAME NIC0_IP NIC0_GATEWAY NIC_COUNT

    log_info "Fetched metadata:"
    log_info "  INSTANCE_ID=$INSTANCE_ID"
    log_info "  PROJECT_ID=$PROJECT_ID"
    log_info "  HOSTNAME=$HOSTNAME"
    log_info "  ZONE=$ZONE"
    log_info "  NETWORK_NAME=$NETWORK_NAME"
    log_info "  NIC0_IP=$NIC0_IP"
    log_info "  NIC0_GATEWAY=$NIC0_GATEWAY"
    log_info "  NIC_COUNT=$NIC_COUNT"
}

# Run only on DHCP BOUND or RENEW
if [[ "${reason:-}" == "BOUND" || "${reason:-}" == "RENEW" ]]; then
    init_metadata_variables
    # Optional: downstream integration
    # /usr/local/bin/update_squid_config.sh "$NIC0_IP" "$PROJECT_ID" "$ZONE" ...
fi

```
