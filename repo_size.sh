#!/bin/bash

# Replace with your organization name
ORG="your-organization-name"

# Get list of repositories in the organization
REPOS=$(gh repo list $ORG --limit 1000 --json name --jq '.[].name')

TOTAL_SIZE=0

# Loop through each repository to get its size
for REPO in $REPOS; do
  REPO_SIZE=$(gh api repos/$ORG/$REPO --jq '.size')
  TOTAL_SIZE=$((TOTAL_SIZE + REPO_SIZE))
done

# Convert size from KB to GB
TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

echo "Total storage used by all repositories in the organization: $TOTAL_SIZE_GB GB"
