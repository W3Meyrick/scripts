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

NIC_COUNT=$(curl -s --connect-timeout 2 --max-time 5 \
    -H "$HEADER" \
    "${METADATA_URL}/instance/network-interfaces/?recursive=true" \
    | grep -c '"mac":') || {
        log_error "Failed to count network interfaces"
        exit 1
    }

if [[ "$NIC_COUNT" -lt 1 ]]; then
    log_error "NIC count appears invalid or zero"
    exit 1
fi

```

```bash
#!/bin/bash

set -euo pipefail

METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
HEADER="Metadata-Flavor: Google"

log_info()  { logger -t gcp-metadata-init "INFO: $*"; }
log_warn()  { logger -t gcp-metadata-init "WARN: $*"; }
log_error() { logger -t gcp-metadata-init "ERROR: $*"; }

# Ensure jq is available
command -v jq >/dev/null 2>&1 || {
  log_error "'jq' is required but not found. Install it first."
  exit 1
}

init_metadata_variables() {
  log_info "Fetching GCP metadata in one call..."

  # Fetch all instance metadata in one request
  ALL_METADATA=$(curl -s --connect-timeout 2 --max-time 5 \
    -H "$HEADER" \
    "${METADATA_URL}/instance/?recursive=true") || {
      log_error "Failed to retrieve instance metadata"
      exit 1
  }

  # Fetch project ID (separate metadata tree)
  PROJECT_ID=$(curl -s --connect-timeout 2 --max-time 5 \
    -H "$HEADER" \
    "${METADATA_URL}/project/project-id") || {
      log_error "Failed to retrieve project ID"
      exit 1
  }

  # Extract and validate metadata values using jq
  INSTANCE_ID=$(echo "$ALL_METADATA" | jq -r '.id')
  HOSTNAME=$(echo "$ALL_METADATA" | jq -r '.hostname')
  ZONE=$(echo "$ALL_METADATA" | jq -r '.zone' | awk -F/ '{print $NF}')
  NETWORK_URI=$(echo "$ALL_METADATA" | jq -r '.networkInterfaces[0].network')
  NETWORK_NAME="${NETWORK_URI##*/}"
  NIC0_IP=$(echo "$ALL_METADATA" | jq -r '.networkInterfaces[0].ip')
  NIC0_GATEWAY=$(echo "$ALL_METADATA" | jq -r '.networkInterfaces[0].gateway')
  NIC_COUNT=$(echo "$ALL_METADATA" | jq '.networkInterfaces | length')

  # Simple format checks
  [[ "$INSTANCE_ID" =~ ^[0-9]{10,20}$ ]] || {
    log_error "Invalid INSTANCE_ID: $INSTANCE_ID"
    exit 1
  }

  [[ "$PROJECT_ID" =~ ^[a-z][a-z0-9\-]{4,61}[a-z0-9]$ ]] || {
    log_error "Invalid PROJECT_ID: $PROJECT_ID"
    exit 1
  }

  [[ "$HOSTNAME" =~ ^[a-z0-9\-]+\.c\.[a-z0-9\-]+\.internal$ ]] || {
    log_error "Invalid HOSTNAME: $HOSTNAME"
    exit 1
  }

  [[ "$ZONE" =~ ^[a-z0-9\-]+$ ]] || {
    log_error "Invalid ZONE: $ZONE"
    exit 1
  }

  [[ "$NETWORK_NAME" =~ ^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$ ]] || {
    log_error "Invalid NETWORK_NAME: $NETWORK_NAME"
    exit 1
  }

  [[ "$NIC0_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || {
    log_error "Invalid NIC0_IP: $NIC0_IP"
    exit 1
  }

  [[ "$NIC0_GATEWAY" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || {
    log_error "Invalid NIC0_GATEWAY: $NIC0_GATEWAY"
    exit 1
  }

  [[ "$NIC_COUNT" -ge 1 ]] || {
    log_error "NIC_COUNT is invalid: $NIC_COUNT"
    exit 1
  }

  # Export and log
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

# Only run on new or renewed DHCP lease
if [[ "${reason:-}" == "BOUND" || "${reason:-}" == "RENEW" ]]; then
  init_metadata_variables
  # Optionally: hand off to config script
  # /usr/local/bin/update_squid_config.sh "$NIC0_IP" "$PROJECT_ID" "$ZONE"
fi

```
