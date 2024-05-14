#!/bin/bash

# Get the current working directory
cwd=$(pwd)

# Get a list of all the Terraform files in the current working directory and its subdirectories
terraform_files=$(find "$cwd" -name "*.tf")

# Get the Terraform state file
state_file="$cwd/terraform.tfstate"

# Create a temporary file to store the resources in the Terraform state file
tmp_file=$(mktemp)

# Get the resources in the Terraform state file
terraform state list > "$tmp_file"

# Create a list of all the Terraform files that have resources that exist in the Terraform state file
matching_files=()
for terraform_file in $terraform_files; do
    # Get the resources defined in the Terraform file
    resources_in_file=$(awk '/^resource / {print $2}' "$terraform_file")

    # Check if any of the resources in the Terraform file exist in the Terraform state file
    for resource in $resources_in_file; do
        if grep -q "$resource" "$tmp_file"; then
            matching_files+=("$terraform_file")
            break
        fi
    done
done

# Print the list of matching Terraform files
echo "Matching Terraform files:"
for matching_file in "${matching_files[@]}"; do
    echo "$matching_file"
done

# Delete the temporary file
rm "$tmp_file"


#!/bin/bash

# Get the current working directory
cwd=$(pwd)

# Find all Terraform files in the current working directory
terraform_files=$(find "$cwd" -name "*.tf")

# Get the Terraform state file
state_file="$cwd/terraform.tfstate"

# Extract resources and modules from the Terraform state file
resources_and_modules=$(terraform state list)

# Create an associative array to store Terraform files with resources or modules
declare -A matching_files

# Iterate over each Terraform file
for terraform_file in $terraform_files; do
    # Check if any resource or module in the Terraform file exists in the state
    while read -r item; do
        if grep -q "$item" <<< "$resources_and_modules"; then
            matching_files["$terraform_file"]=1
            break
        fi
    done < <(grep -Eo 'resource|module\s+"\w+"' "$terraform_file" | cut -d '"' -f 2)
done

# Print matching Terraform files
echo "Matching Terraform files:"
for matching_file in "${!matching_files[@]}"; do
    echo "$matching_file"
done
