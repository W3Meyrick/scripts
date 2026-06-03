#!/bin/bash
# Creates a GCP VM that continuously tests Compute/Storage APIs and DNS servers.
# Run once to provision. No SSH access is needed after creation.
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — fill these in before running
# ──────────────────────────────────────────────────────────────────────────────
PROJECT_ID="YOUR_PROJECT_ID"
ZONE="us-central1-a"
INSTANCE_NAME="api-dns-tester"
MACHINE_TYPE="e2-micro"
NETWORK="default"
SUBNET="default"

# Custom RHEL-based image — must be from your organisation's image project.
# Google-supplied images are not permitted in this environment.
IMAGE_FAMILY="YOUR_RHEL_IMAGE_FAMILY"
IMAGE_PROJECT="YOUR_IMAGE_PROJECT"

# Full email of the existing service account to attach to the instance.
# The account must already have: roles/logging.logWriter,
# roles/compute.viewer, and roles/storage.objectViewer.
SERVICE_ACCOUNT_EMAIL="YOUR_SERVICE_ACCOUNT@${PROJECT_ID}.iam.gserviceaccount.com"

# Set to "true" to attach an external IP. Required if your DNS servers are on
# the public internet and your VPC has no Cloud NAT configured. If "false",
# Google APIs are still reachable via Private Google Access (which must be
# enabled on the subnet), but external DNS servers will be unreachable.
USE_EXTERNAL_IP="true"
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/2] Creating compute instance: ${INSTANCE_NAME}"
ADDRESS_FLAG="--no-address"
if [[ "${USE_EXTERNAL_IP}" == "true" ]]; then
  ADDRESS_FLAG=""
fi

gcloud compute instances create "${INSTANCE_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --service-account="${SERVICE_ACCOUNT_EMAIL}" \
  --scopes="cloud-platform" \
  --network="${NETWORK}" \
  --subnet="${SUBNET}" \
  ${ADDRESS_FLAG} \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --metadata-from-file="startup-script=${SCRIPT_DIR}/startup-script.sh" \
  --tags="api-dns-tester" \
  --shielded-secure-boot \
  --shielded-vtpm

echo "==> [2/2] Done. The VM will take ~2 minutes to finish setup on first boot."
echo ""
echo "Monitor startup output:"
echo "  gcloud compute instances get-serial-port-output ${INSTANCE_NAME} \\"
echo "    --zone=${ZONE} --project=${PROJECT_ID}"
echo ""
echo "View test logs in Cloud Logging:"
echo "  gcloud logging read \\"
echo "    'logName=\"projects/${PROJECT_ID}/logs/gcp-api-dns-tester\"' \\"
echo "    --project=${PROJECT_ID} --limit=50 --order=desc"
echo ""
echo "To destroy when done:"
echo "  gcloud compute instances delete ${INSTANCE_NAME} --zone=${ZONE} --project=${PROJECT_ID}"
