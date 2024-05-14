# Performance and Stress Testing Documentation

## Strategy

### Introduction:
The objective of this strategy is to conduct stress and performance testing on the Google Cloud Platform (GCP) Shared Services, including API proxies (Squid), API forwarders (nginx transparent proxies), and DNS (unbound). These services are critical components providing access to the bank's GCP cloud platform. All services are deployed on Google Compute Managed Instance Groups to ensure scalability and reliability.

### Objective:
This testing aims to evaluate the performance capabilities of the GCP Shared Services in a single-instance scenario. The chosen test tool for this purpose is Locust. The types of tests to be performed include load testing, stress testing, and endurance testing to assess the performance and scalability of the shared services.

### Application Functionality and Business Processes Supported:

API Proxies (Squid): These proxies serve as gateways for users to access the cloud platform securely from on-premises locations. They handle incoming requests, provide caching, and enforce access controls.
API Forwarders (nginx Transparent Proxies): These forwarders facilitate access to Google's APIs from within the cloud platform. They optimize network traffic and enhance performance by transparently intercepting and forwarding requests.
DNS Services (Unbound): DNS services are utilized by instances on the platform to perform DNS lookups against on-premises DNS servers. They resolve domain names to IP addresses, enabling communication with external services.
Performance and Stress Test Process:

1. API Proxy (Squid):
- Load Testing: Simulate varying levels of user traffic accessing the cloud platform through the Squid API proxies. Measure response times, throughput, and error rates under increasing loads.
- Stress Testing: Apply maximum or near-maximum load to the Squid proxies to determine their breaking point. Assess how they handle extreme levels of traffic and whether they degrade gracefully or fail.
- Endurance Testing: Sustain a steady load on the Squid proxies over an extended period to evaluate their stability and resource utilization. Monitor for memory leaks, performance degradation, or other issues over time.

2. API Forwarder (nginx Transparent Proxies):**
- Load Testing: Generate synthetic traffic to mimic requests to Google's APIs through the nginx transparent proxies. Evaluate the proxies' ability to handle concurrent connections and process requests efficiently.
- Stress Testing: Subject the nginx transparent proxies to heavy loads beyond their normal capacity. Monitor for any performance bottlenecks, such as CPU or memory saturation, and assess their impact on response times.
- Endurance Testing: Maintain a sustained load on the nginx proxies for an extended duration to identify any resource leaks or degradation in performance over time.

3. DNS Services (Unbound):
- Load Testing: Simulate DNS lookup requests from instances on the GCP platform to the Unbound DNS servers. Measure response times and throughput under varying query rates.
- Stress Testing: Increase the query rate to the Unbound DNS servers to determine their maximum capacity. Monitor for any signs of DNS resolution failures or increased response times under stress.
- Endurance Testing: Keep a consistent load on the Unbound DNS servers for an extended period to ensure they maintain stable performance and do not exhibit any memory leaks or other issues over time.

### Conclusion:
By conducting comprehensive performance and stress testing on the GCP Shared Services, including API proxies, API forwarders, and DNS services, we aim to identify any performance bottlenecks, scalability limitations, or stability concerns. The insights gained from these tests will inform optimizations and improvements to ensure the reliability and efficiency of the bank's GCP cloud platform.

## Process

1. API Proxies (Squid):

**Technical Steps:**
- Python Script:
  - Write a Python script defining Locust tasks for interacting with the Squid API proxies.
  - Use the locust library to define user behavior, including making HTTP requests to the Squid proxies.
  - Implement task logic to vary request payloads, headers, and authentication tokens for realistic simulation.

**Metrics:**
- Response Time
- Request Throughput
- Error Rate

**Implementation Plan:**
- Python Script: squid_proxy_test.py
  - Define Locust tasks for interacting with Squid API proxies.
  - Configure task execution rates and ramp-up periods.
  - Run distributed tests using Locust if necessary.

2. API Forwarders (nginx Transparent Proxies):

**Technical Steps:**
- Python Script:
  - Create a Python script defining Locust tasks for simulating traffic to nginx transparent proxies.
  - Utilize the locust library to specify different types of requests targeting Google's APIs.
  - Customize task logic to mimic real-world traffic patterns and distribution.

**Metrics:**
- Connection Time
- Response Time
- CPU and Memory Usage

**Implementation Plan:**
- Python Script: nginx_proxy_test.py
  - Develop Locust tasks for interacting with nginx transparent proxies.
  - Configure test scenarios for varying levels of traffic.
  - Monitor performance metrics during test execution.


3. DNS Services (Unbound):

**Technical Steps:**
- Python Script:
  - Write a Python script defining Locust tasks for simulating DNS lookup requests to Unbound DNS servers.
  - Utilize the locust library to specify different domain names and query types.
  - Implement task logic to handle DNS resolution responses and validate results.

**Metrics:**
- DNS Resolution Time
- Query Throughput
- DNS Cache Hit Rate

**Implementation Plan:**
- Python Script: dns_service_test.py
  - Develop Locust tasks for performing DNS lookups against Unbound DNS servers.
  - Configure test scenarios for varying query rates and patterns.
  - Analyze performance metrics to identify latency issues or capacity constraints.
  - By following this actionable plan, you can effectively conduct stress and performance testing for each service using Locust and Python scripts tailored to the specific requirements of API proxies, API forwarders, and DNS services.

## Technical Steps:

1. API Proxies (Squid) - squid_proxy_test.py:

```python
from locust import HttpUser, task, between

class SquidProxyUser(HttpUser):
    wait_time = between(1, 3)  # Wait time between requests

    @task
    def access_resource(self):
        # Define HTTP request to Squid proxy
        self.client.get("/api/resource", headers={"Authorization": "Bearer token"})
```

2. API Forwarders (nginx Transparent Proxies) - nginx_proxy_test.py:

```python
from locust import HttpUser, task, between

class NginxProxyUser(HttpUser):
    wait_time = between(0.5, 2)  # Wait time between requests

    @task
    def access_google_api(self):
        # Define HTTP request to nginx proxy
        self.client.get("/google-api/resource")
```

3. DNS Services (Unbound) - dns_service_test.py:

```python
from locust import User, task, between
import socket

class DNSUser(User):
    wait_time = between(1, 5)  # Wait time between queries

    @task
    def perform_dns_lookup(self):
        # Define DNS lookup request
        try:
            socket.gethostbyname("example.com")
        except socket.gaierror as e:
            pass  # Handle DNS resolution errors if needed
```

These scripts define Locust users that simulate interactions with the Squid API proxies, nginx transparent proxies, and DNS servers. Each user class contains one or more tasks representing different actions or requests to be performed during the test.

To run these scripts, you'll need to install Locust (pip install locust) and then execute them from the command line using the Locust command (locust -f <script_name>). You can then access the Locust web interface to configure and start the test, monitor performance metrics, and analyze results.