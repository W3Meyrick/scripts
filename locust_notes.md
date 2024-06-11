


```python
import locust
import subprocess
import random

# Define the proxy IP address as a variable
PROXY_IP = "192.168.1.10"
PROXY_PORT = "3128"

# Function to get an access token using gcloud
def get_access_token():
    result = subprocess.run(
        ["gcloud", "auth", "print-access-token"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True
    )
    return result.stdout.strip()

# Retrieve the access token once and store it
ACCESS_TOKEN = get_access_token()

# Define the map of projects and zones
PROJECT_ZONE_MAP = {
    "project1": ["zone1a", "zone1b", "zone1c"],
    "project2": ["zone2a", "zone2b", "zone2c"],
    "project3": ["zone3a", "zone3b", "zone3c"],
}

# Define the list of storage buckets
STORAGE_BUCKETS = [
    "bucket1",
    "bucket2",
    "bucket3",
]

# Locust task set for Compute Engine API
class ComputeEngineBehavior(locust.TaskSet):

    @locust.task
    def compute_api_test(self):
        # Randomly select a project and a zone
        project = random.choice(list(PROJECT_ZONE_MAP.keys()))
        zone = random.choice(PROJECT_ZONE_MAP[project])
        
        # Compute Engine API URL (relative)
        compute_api_url = f"/compute/v1/projects/{project}/zones/{zone}/instances"
        
        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {ACCESS_TOKEN}",
            "Content-Type": "application/json"
        }

        # Make a GET request to the Compute Engine API via proxy
        with self.client.get(compute_api_url, headers=headers, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Failed with status code {response.status_code}")
            else:
                response.success()

# Locust task set for Storage API
class StorageBehavior(locust.TaskSet):

    @locust.task
    def storage_api_test(self):
        # Randomly select a storage bucket
        bucket = random.choice(STORAGE_BUCKETS)
        
        # Storage API URL (relative)
        storage_api_url = f"/storage/v1/b/{bucket}/o"

        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {ACCESS_TOKEN}",
            "Content-Type": "application/json"
        }

        # Make a GET request to the Storage API via proxy
        with self.client.get(storage_api_url, headers=headers, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Failed with status code {response.status_code}")
            else:
                response.success()

# User class for Compute Engine
class ComputeEngineUser(locust.HttpUser):
    tasks = [ComputeEngineBehavior]
    host = "https://compute.googleapis.com"
    wait_time = locust.between(1, 5)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.client.proxies = {
            "http": f"http://{PROXY_IP}:{PROXY_PORT}",
        }

# User class for Storage
class StorageUser(locust.HttpUser):
    tasks = [StorageBehavior]
    host = "https://storage.googleapis.com"
    wait_time = locust.between(1, 5)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.client.proxies = {
            "http": f"http://{PROXY_IP}:{PROXY_PORT}",
        }
```

```bash
sudo locust -f locustfile.py --host=https://www.googleapis.com --web-port 80
```
