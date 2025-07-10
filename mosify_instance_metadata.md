```bash
#!/bin/bash

# Get all instance IDs
instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)

for instance_id in $instance_ids; do
  # Check if instance is part of an Auto Scaling Group by looking for the tag "aws:autoscaling:groupName"
  asg_tag=$(aws ec2 describe-tags \
    --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=aws:autoscaling:groupName" \
    --query 'Tags[*].Value' --output text)

  if [[ -n "$asg_tag" ]]; then
    echo "Instance $instance_id is part of ASG $asg_tag. Modifying metadata options..."
    
    aws ec2 modify-instance-metadata-options \
      --instance-id "$instance_id" \
      --instance-metadata-tags enabled
  else
    echo "Instance $instance_id is NOT part of an ASG. Skipping..."
  fi
done
```
