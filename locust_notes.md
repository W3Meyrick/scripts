


```python
import locust
import subprocess

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

# Locust task set for Compute Engine API
class ComputeEngineBehavior(locust.TaskSet):

    def on_start(self):
        # Get access token
        self.access_token = get_access_token()

    @locust.task
    def compute_api_test(self):
        # Compute Engine API URL (relative)
        compute_api_url = "/compute/v1/projects/YOUR_PROJECT_ID/zones/YOUR_ZONE/instances"
        
        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {self.access_token}",
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

    def on_start(self):
        # Get access token
        self.access_token = get_access_token()

    @locust.task
    def storage_api_test(self):
        # Storage API URL (relative)
        storage_api_url = "/storage/v1/b/YOUR_BUCKET_NAME/o"

        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {self.access_token}",
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
            "https": f"http://{PROXY_IP}:{PROXY_PORT}",
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
            "https": f"http://{PROXY_IP}:{PROXY_PORT}",
        }

if __name__ == "__main__":
    import os
    os.system("locust -f gcp_test_script.py --web-port 80"
```

```bash
sudo locust -f locustfile.py --host=https://www.googleapis.com --web-port 80
```
