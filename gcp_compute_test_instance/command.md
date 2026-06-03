```bash
curl -sf -w "HTTP %{http_code} — connected to %{remote_ip}\n" \
  -o /dev/null "https://discovery.googleapis.com/discovery/v1/apis"
```