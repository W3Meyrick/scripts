```bash
curl -sf -w "HTTP %{http_code} — connected to %{remote_ip}\n" \
  -o /dev/null "https://discovery.googleapis.com/discovery/v1/apis"
```

Same pattern as before, just filter on the test field:


gcloud logging read \
  'logName="projects/YOUR_PROJECT_ID/logs/gcp-api-dns-tester" AND jsonPayload.test="gcr_api"' \
  --project=YOUR_PROJECT_ID \
  --order=asc \
  --format=json
Add a time window if you want to scope it to the DR test:


gcloud logging read \
  'logName="projects/YOUR_PROJECT_ID/logs/gcp-api-dns-tester" AND jsonPayload.test="gcr_api" AND timestamp>="2026-06-04T14:00:00Z" AND timestamp<="2026-06-04T15:00:00Z"' \
  --project=YOUR_PROJECT_ID \
  --order=asc \
  --format=json
Or if you just want a quick summary table:


gcloud logging read \
  'logName="projects/YOUR_PROJECT_ID/logs/gcp-api-dns-tester" AND jsonPayload.test="gcr_api"' \
  --project=YOUR_PROJECT_ID \
  --order=asc \
  --format='table(timestamp,jsonPayload.result,jsonPayload.duration_ms,jsonPayload.detail)'
