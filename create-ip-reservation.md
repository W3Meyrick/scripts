#!/bin/bash

# JSON file containing the IP address details
json_file="addresses.json"

# Iterate over each entry in the JSON file
jq -c '.[]' "$json_file" | while read -r address; do
  name=$(echo "$address" | jq -r '.name')
  project=$(echo "$address" | jq -r '.project')
  subnet=$(echo "$address" | jq -r '.subnet')
  region=$(echo "$address" | jq -r '.region')

  # Set the project
  gcloud config set project "$project" > /dev/null 2>&1

  # Create the IP address
  ip_address=$(gcloud compute addresses create "$name" \
    --region="$region" \
    --subnet="$subnet" \
    --format="get(address)" 2>/dev/null)

  # Print the created IP address
  echo "$ip_address"

  # Clean up by deleting the created IP address
  gcloud compute addresses delete "$name" \
    --region="$region" \
    --quiet > /dev/null 2>&1
done
