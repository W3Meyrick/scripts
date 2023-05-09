#!/bin/bash

# Specify the path to the CSV file containing instance names
csv_file_path="path/to/instances.csv"

# Read the CSV file and loop through each line
while IFS= read -r instance_name || [[ -n "$instance_name" ]]; do
  # Execute the AWS CLI command to describe the instance and retrieve its status message
  status_message=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" --query "Reservations[*].Instances[*].State.StatusMessage" --output text)
  
  # Output the instance name and its status message
  echo "$instance_name   $status_message"
done < "$csv_file_path"