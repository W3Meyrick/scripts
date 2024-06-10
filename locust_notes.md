


```python
import locust

# Locust task set
class GCPUserBehavior(locust.TaskSet):

    @locust.task
    def compute_api_test(self):
        # Replace with your Compute Engine API URL
        compute_api_url = "https://www.googleapis.com/compute/v1/projects/YOUR_PROJECT_ID/zones/YOUR_ZONE/instances"

        # Make a GET request to the Compute Engine API via proxy
        with self.client.get(compute_api_url, proxies={"http": "http://192.168.1.10:3128", "https": "http://192.168.1.10:3128"}, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Failed with status code {response.status_code}")
            else:
                response.success()

    @locust.task
    def storage_api_test(self):
        # Replace with your Storage API URL
        storage_api_url = "https://www.googleapis.com/storage/v1/b/YOUR_BUCKET_NAME/o"

        # Make a GET request to the Storage API via proxy
        with self.client.get(storage_api_url, proxies={"http": "http://192.168.1.10:3128", "https": "http://192.168.1.10:3128"}, catch_response=True) as response:
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
