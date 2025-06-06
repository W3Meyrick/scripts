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
```
