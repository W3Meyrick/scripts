```bash
I have this inside a bash script that runs with set -euo pipefail and it fails when there's network issues. How can I add retry logic? currentClusterState=$(curl -u ${cmUser}:${cmPass} ${cmUrl}:7183/api/v45/clusters -k|jq -r '.items[]'|jq .entityStatus|sed -e 's/"//g')
```
```bash
retry() {
  local -r max_attempts="$1"; shift
  local attempt=1 delay=2

  while :; do
    if "$@"; then
      return 0
    fi
    if (( attempt >= max_attempts )); then
      return 1
    fi
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))   # exponential backoff
  done
}

get_cluster_state() {
  curl -sS --fail-with-body \
    -u "${cmUser}:${cmPass}" \
    -k "${cmUrl}:7183/api/v45/clusters" \
  | jq -r '.items[].entityStatus'
}

currentClusterState="$(retry 6 get_cluster_state)"

```
