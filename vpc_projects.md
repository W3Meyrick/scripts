```bash
#!/bin/bash

# List all host projects
HOST_PROJECTS=$(gcloud compute shared-vpc list-host-projects --format="value(projectId)")

echo "Shared VPC Summary:"
echo "-------------------------------------"

for HOST in $HOST_PROJECTS; do
    echo "Host Project: $HOST"

    # List service projects for each host project
    SERVICE_PROJECTS=$(gcloud compute shared-vpc list-service-projects --host-project=$HOST --format="value(projectId)")

    # Count the number of service projects
    SERVICE_COUNT=$(echo "$SERVICE_PROJECTS" | wc -l)

    echo "  - Number of Service Projects: $SERVICE_COUNT"

    # Optionally list the service projects
    echo "  - Service Projects: $SERVICE_PROJECTS"
    echo
done
```
