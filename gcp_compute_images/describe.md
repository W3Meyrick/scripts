#!/bin/bash

# Function to describe and list old images for a given project and family
describe_old_images() {
    local project="$1"
    local family="$2"
    
    # Get a list of images for the specified family and project
    images=$(gcloud compute images list --project="$project" --family="$family" --format=json)
    
    # Calculate the cutoff date (6 months ago)
    cutoff_date=$(date -d "6 months ago" --utc +%Y-%m-%dT%H:%M:%S.%NZ)

    # Describe and list images older than 6 months
    for image in $(echo "$images" | jq -c '.[]'); do
        creation_timestamp=$(echo "$image" | jq -r '.creationTimestamp')
        
        if [ "$creation_timestamp" \< "$cutoff_date" ]; then
            image_name=$(echo "$image" | jq -r '.name')
            echo "Describing image $image_name created on $creation_timestamp"
            gcloud compute images describe "$image_name" --project="$project"
            echo "---"
        fi
    done
}

# Read the JSON file containing the list of image families and projects
json_file="image_data.json"
if [ ! -f "$json_file" ]; then
    echo "Error: JSON file $json_file not found."
    exit 1
fi

# Iterate through each entry in the JSON file and describe old images
for entry in $(jq -c '.[]' "$json_file"); do
    project=$(echo "$entry" | jq -r '.project')
    family=$(echo "$entry" | jq -r '.family')
    describe_old_images "$project" "$family"
done