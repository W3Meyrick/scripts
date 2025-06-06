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

# Generic metadata fetch with retries, timeouts, HTTP checks, and regex validation
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

# Use fetch_metadata with expected formats for each field
init_metadata_variables() {
    log_info "Starting GCP metadata fetch..."

    INSTANCE_ID=$(fetch_metadata "/instance/id" '^[0-9]{10,20}$') || exit 1
    PROJECT_ID=$(fetch_metadata "/project/project-id" '^[a-z][a-z0-9\-]{4,61}[a-z0-9]$') || exit 1
    HOSTNAME=$(fetch_metadata "/instance/hostname" '^[a-z0-9\-]+\.c\.[a-z0-9\-]+\.internal$') || exit 1

    ZONE_URI=$(fetch_metadata "/instance/zone" '^projects/[0-9]+/zones/[a-z0-9\-]+$') || exit 1
    ZONE="${ZONE_URI##*/}"

    NETWORK_URI=$(fetch_metadata "/instance/network-interfaces/0/network" '^projects/[0-9]+/networks/[a-z]([-a-z0-9]{0,61}[a-z0-9])?$') || exit 1
    NETWORK_NAME="${NETWORK_URI##*/}"

    export INSTANCE_ID PROJECT_ID HOSTNAME ZONE NETWORK_NAME

    log_info "Fetched: INSTANCE_ID=$INSTANCE_ID, PROJECT_ID=$PROJECT_ID, HOSTNAME=$HOSTNAME, ZONE=$ZONE, NETWORK_NAME=$NETWORK_NAME"
}

# Only run during DHCP lease acquisition or renewal
if [[ "${reason:-}" == "BOUND" || "${reason:-}" == "RENEW" ]]; then
    init_metadata_variables
    # Hook downstream logic here
    # /usr/local/bin/update_squid_config.sh "$PROJECT_ID" "$ZONE" "$NETWORK_NAME" ...
fi

```
