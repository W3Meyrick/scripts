# GCP API & DNS Continuous Tester

A GCP compute instance that continuously tests Compute Engine and Cloud Storage API reachability, and DNS resolution against a set of specified nameservers. Results are written as structured log entries to Cloud Logging and the tests run until the instance is shut down or destroyed.

No Python or additional packages are required — the tester uses only `curl` and `dig`, both present on RHEL 8 base images.

---

## Files

| File | Purpose |
|------|---------|
| `create-instance.sh` | Run once from your workstation to create the VM |
| `startup-script.sh` | Passed to the VM as a metadata startup script; runs on every boot |
| `test-api-proxy.sh` | Run from your workstation during the DR window to test the API proxy |

---

## Prerequisites

- `gcloud` CLI installed and authenticated
- An existing service account with the following roles:
  - `roles/logging.logWriter`
  - `roles/compute.viewer`
  - `roles/storage.objectViewer`
- A custom RHEL 8-based compute image in your organisation's image project
- If DNS servers to be tested are on the public internet and the VPC has no Cloud NAT: set `USE_EXTERNAL_IP="true"` in `create-instance.sh`

---

## Configuration

### `create-instance.sh`

Set these variables at the top of the file before running:

| Variable | Description |
|----------|-------------|
| `PROJECT_ID` | GCP project to create the instance in |
| `ZONE` | Zone to deploy to (e.g. `europe-west2-a`) |
| `INSTANCE_NAME` | Name for the compute instance |
| `MACHINE_TYPE` | Machine type (e.g. `e2-micro`) |
| `NETWORK` / `SUBNET` | VPC network and subnet name |
| `IMAGE_FAMILY` | Your organisation's RHEL-based image family |
| `IMAGE_PROJECT` | GCP project that hosts the image |
| `SERVICE_ACCOUNT_EMAIL` | Full email of the pre-existing service account |
| `USE_EXTERNAL_IP` | `true` if the instance needs a public IP; `false` for private-only |

### `startup-script.sh` — tester configuration

Edit the configuration block near the top of the embedded `tester.sh` section:

| Variable | Description |
|----------|-------------|
| `DNS_SERVERS` | Array of DNS server IPs to query |
| `DNS_LOOKUP_HOSTNAME` | Hostname to resolve against each server |
| `TEST_INTERVAL_SECONDS` | Seconds between test runs (default: `60`) |

---

## Deployment

```bash
./create-instance.sh
```

The instance will take approximately 2 minutes to complete setup on first boot.

**Monitor startup:**
```bash
gcloud compute instances get-serial-port-output INSTANCE_NAME \
  --zone=ZONE --project=PROJECT_ID
```

---

## Viewing logs

Live tail in the console:

```bash
gcloud logging read \
  'logName="projects/PROJECT_ID/logs/gcp-api-dns-tester"' \
  --project=PROJECT_ID \
  --order=desc \
  --limit=50
```

Each entry is structured JSON with the following fields:

| Field | Description |
|-------|-------------|
| `test` | Test name: `compute_api`, `storage_api`, `dns_<server_ip>` |
| `result` | `PASS` or `FAIL` |
| `duration_ms` | How long the test took |
| `detail` | Human-readable outcome (addresses resolved, HTTP status, etc.) |
| `instance` | Instance name |

Failed tests are logged at `ERROR` severity and can be used to trigger Cloud Monitoring alerting policies.

---

## Exporting logs for a DR test report

Run from your workstation after the test window has completed. Adjust `START_TIME` and `END_TIME` to match your DR test window.

**Full log export (JSON):**
```bash
gcloud logging read \
  'logName="projects/PROJECT_ID/logs/gcp-api-dns-tester" AND timestamp>="START_TIME" AND timestamp<="END_TIME"' \
  --project=PROJECT_ID \
  --order=asc \
  --format=json \
  > dr-test-full.json
```

**Failures only:**
```bash
gcloud logging read \
  'logName="projects/PROJECT_ID/logs/gcp-api-dns-tester" AND timestamp>="START_TIME" AND timestamp<="END_TIME" AND jsonPayload.result="FAIL"' \
  --project=PROJECT_ID \
  --order=asc \
  --format=json \
  > dr-test-failures.json
```

**Readable summary table:**
```bash
gcloud logging read \
  'logName="projects/PROJECT_ID/logs/gcp-api-dns-tester" AND timestamp>="START_TIME" AND timestamp<="END_TIME"' \
  --project=PROJECT_ID \
  --order=asc \
  --format='table(timestamp,jsonPayload.test,jsonPayload.result,jsonPayload.duration_ms,jsonPayload.detail)' \
  > dr-test-summary.txt
```

Timestamps must be in ISO 8601 UTC format, e.g. `2026-06-03T14:00:00Z`.

Cloud Logging retains logs for 30 days by default, so the export does not need to be run immediately after the test window.

---

---

## API proxy test (workstation)

`test-api-proxy.sh` is run from your workstation during the DR test window. It tests that gcloud commands work correctly through the API proxy and logs results in the same JSON structure as the VM tester, so both can be queried together for the report.

**Prerequisites:**
- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- The API proxy configured in gcloud before running:
  ```bash
  gcloud config set proxy/type http
  gcloud config set proxy/address YOUR_PROXY_HOST
  gcloud config set proxy/port YOUR_PROXY_PORT
  ```
  Or via environment variable: `HTTPS_PROXY=http://host:port`
- Authenticated user must have `roles/logging.logWriter` on the project if `USE_CLOUD_LOGGING="true"`

**Configuration** — set at the top of the file:

| Variable | Description |
|----------|-------------|
| `PROJECT_ID` | GCP project to test against |
| `TEST_DURATION_MINUTES` | How long to run (default: `60`) |
| `TEST_INTERVAL_SECONDS` | Seconds between test cycles (default: `60`) |
| `USE_CLOUD_LOGGING` | `true` to also write to Cloud Logging; `false` for local file only |

**Run:**
```bash
./test-api-proxy.sh
```

Results are always written to a local `api-proxy-test-<timestamp>.jsonl` file. If `USE_CLOUD_LOGGING="true"`, they are also written to Cloud Logging under the log name `gcp-api-proxy-test`.

**Query proxy test logs for the DR report:**
```bash
gcloud logging read \
  'logName="projects/PROJECT_ID/logs/gcp-api-proxy-test" AND timestamp>="START_TIME" AND timestamp<="END_TIME"' \
  --project=PROJECT_ID \
  --order=asc \
  --format=json \
  > dr-test-proxy.json
```

---

## Teardown

```bash
gcloud compute instances delete INSTANCE_NAME --zone=ZONE --project=PROJECT_ID
```
