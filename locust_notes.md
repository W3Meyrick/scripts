


```python
import locust
import requests
import subprocess

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

# Locust task set
class GCPUserBehavior(locust.TaskSet):

    @locust.task
    def compute_api_test(self):
        # Replace with your Compute Engine API URL
        compute_api_url = "https://www.googleapis.com/compute/v1/projects/YOUR_PROJECT_ID/zones/YOUR_ZONE/instances"
        
        # Get access token
        access_token = get_access_token()
        
        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        # Make a GET request to the Compute Engine API via proxy
        with self.client.get(compute_api_url, headers=headers, proxies={"http": "http://192.168.1.10:3128", "https": "http://192.168.1.10:3128"}, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Failed with status code {response.status_code}")
            else:
                response.success()

    @locust.task
    def storage_api_test(self):
        # Replace with your Storage API URL
        storage_api_url = "https://www.googleapis.com/storage/v1/b/YOUR_BUCKET_NAME/o"

        # Get access token
        access_token = get_access_token()

        # Prepare headers with the access token
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        # Make a GET request to the Storage API via proxy
        with self.client.get(storage_api_url, headers=headers, proxies={"http": "http://192.168.1.10:3128", "https": "http://192.168.1.10:3128"}, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Failed with status code {response.status_code}")
            else:
                response.success()

class GCPUser(locust.HttpUser):
    tasks = [GCPUserBehavior]
    wait_time = locust.between(1, 5)
```

```bash
sudo locust -f locustfile.py --host=https://www.googleapis.com --web-port 80
```
