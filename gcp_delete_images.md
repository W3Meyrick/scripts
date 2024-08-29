```bash
#!/bin/bash

# Set your variables here
PROJECT_ID="your-project-id"
IMAGE_FAMILY="your-image-family"

# Get the latest image in the family
LATEST_IMAGE=$(gcloud compute images describe-from-family $IMAGE_FAMILY \
  --project=$PROJECT_ID --format="get(name)")

# List all images in the family
ALL_IMAGES=$(gcloud compute images list \
  --project=$PROJECT_ID \
  --filter="family:$IMAGE_FAMILY" \
  --format="get(name)")

# Iterate over all images and delete those that are not the latest
for IMAGE in $ALL_IMAGES; do
  if [ "$IMAGE" != "$LATEST_IMAGE" ]; then
    echo "Deleting image: $IMAGE"
    gcloud compute images delete $IMAGE --project=$PROJECT_ID --quiet
  else
    echo "Keeping latest image: $IMAGE"
  fi
done

echo "Old images deleted, only the latest one remains."
```
