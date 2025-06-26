```bash
#!/bin/bash

# Output CSV file
OUTPUT="teleport_nodes.csv"
echo "hostname,component,environment,project,role,teleport_version,ssh" > "$OUTPUT"

# Get the list of nodes in JSON format
nodes_json=$(tsh ls --format=json)

# Parse each node
echo "$nodes_json" | jq -c '.[]' | while read -r node; do
    hostname=$(echo "$node" | jq -r '.hostname')
    component=$(echo "$node" | jq -r '.labels.component // ""')
    environment=$(echo "$node" | jq -r '.labels.environment // ""')
    project=$(echo "$node" | jq -r '.labels.project // ""')
    role=$(echo "$node" | jq -r '.labels.role // ""')

    # Try SSH as ec2-user and get the teleport version
    version_output=$(tsh ssh "ec2-user@$hostname" "teleport version" 2>/dev/null)
    ssh_status=$?

    if [ $ssh_status -ne 0 ] || [ -z "$version_output" ]; then
        teleport_version="SSH not available"
        ssh_available="false"
    else
        teleport_version=$(echo "$version_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
        ssh_available="true"
    fi

    # Write to CSV
    echo "$hostname,$component,$environment,$project,$role,$teleport_version,$ssh_available" >> "$OUTPUT"
done

echo "Done. Results saved to $OUTPUT"
```

```bash
#!/bin/bash

# Output CSV file
OUTPUT="teleport_nodes.csv"
echo "hostname,component,environment,project,role,teleport_version,ssh" > "$OUTPUT"

# Get the list of nodes
nodes_json=$(tsh ls --format=json)

# Loop through each node safely
while read -r node; do
    hostname=$(echo "$node" | jq -r '.spec.hostname // ""')
    component=$(echo "$node" | jq -r '.spec.labels.component // ""')
    environment=$(echo "$node" | jq -r '.spec.labels.environment // ""')
    project=$(echo "$node" | jq -r '.spec.labels.project // ""')
    role=$(echo "$node" | jq -r '.spec.labels.role // ""')

    if [ -z "$hostname" ]; then
        echo "Skipping node with missing hostname."
        continue
    fi

    echo "Checking $hostname..."

    # Attempt SSH to get the Teleport version
    version_output=$(tsh ssh "ec2-user@$hostname" "teleport version" 2>/dev/null || true)

    if [[ -z "$version_output" ]]; then
        teleport_version=""
        ssh_status="SSH not available"
        echo "SSH failed for $hostname"
    else
        teleport_version=$(echo "$version_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
        ssh_status="OK"
        echo "$hostname is running Teleport version $teleport_version"
    fi

    # Write row to CSV
    echo "\"$hostname\",\"$component\",\"$environment\",\"$project\",\"$role\",\"$teleport_version\",\"$ssh_status\"" >> "$OUTPUT"

done < <(echo "$nodes_json" | jq -c '.[]')

echo "Done. Results saved to $OUTPUT"

```
