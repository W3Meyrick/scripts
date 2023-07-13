import boto3
import yaml

def create_ansible_inventory(tag_key, tag_value, inventory_file):
    ec2_client = boto3.client('ec2')

    response = ec2_client.describe_instances(
        Filters=[
            {
                'Name': f'tag:{tag_key}',
                'Values': [tag_value]
            }
        ]
    )

    instances = response['Reservations']
    inventory = {
        'all': {
            'hosts': {}
        }
    }

    for instance in instances:
        instance_id = instance['Instances'][0]['InstanceId']
        private_ip = instance['Instances'][0]['PrivateIpAddress']

        inventory['all']['hosts'][instance_id] = {
            'ansible_host': private_ip
        }

    with open(inventory_file, 'w') as file:
        yaml.dump(inventory, file)

    print(f"Ansible inventory file '{inventory_file}' has been created.")


# Set the desired tag key, tag value, and inventory file path
tag_key = 'Product'
tag_value = 'Data'
inventory_file = 'ansible_inventory.yaml'

# Call the function to create the Ansible inventory file
create_ansible_inventory(tag_key, tag_value, inventory_file)
