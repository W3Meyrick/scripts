```bash
I have this inside a bash script that runs with set -euo pipefail and it fails when there's network issues. How can I add retry logic? currentClusterState=$(curl -u ${cmUser}:${cmPass} ${cmUrl}:7183/api/v45/clusters -k|jq -r '.items[]'|jq .entityStatus|sed -e 's/"//g')
```
