# Performance Report Guide

## Objective 

The objective of the report is to provide details on performance testing scope, SLA, testing approach followed, type of tests executed, indicating completed investigations and optimisations, details on outstanding risks, bottlenecks, recommendations and next steps to the respective stakeholders. 

## Performance Test Summary (Results and Findings)

### Executive Summary 

Executive summary covers performance testing activities, briefs on the results, observed bottlenecks, issues and potential risks. This section is intended for executives and is the key summary to influence go/no go decisions. 


### Test Summary 

Summary of all tests conducted and corresponding results - average, peak, soak and/or stress testing. Describe the outcome of the tests and whether the test met the performance acceptance criteria. 


### Issues and Recommendations 

Describe recommended fixes, optimisations, and recommendations for any performance defects identified during the tests. 

## Application Overview 

Overview of application functionality, logical architecture, deployment architecture, and any configuration. 

## Performance Testing Scope

### Key Business Use-cases

Provide performance testing scope and levels of testing and provide the key business use cases in a table format with column headings for Use Case, Description, and comments. 

### Performance Testing Acceptance Criteria 

Business capacity, technical capacity, and exceptions. 


### Application Workload Volumes

Provide low, average, and peak workload volumes for the service along with results for performance under the performance test - using at least 20% additional load. 

Example Report: 

# Performance Report

## Objective

The objective of this report is to provide detailed insights into the performance testing of the Squid proxy service, a critical component of the bank's GCP shared services. The aim is to assess the proxy's ability to handle various loads and user scenarios, determine its capacity limits, and identify any performance bottlenecks. This testing ensures that the Squid proxy service can reliably support business operations by enabling secure and efficient access to the cloud platform from on-premises locations. Locust was used as the performance testing tool to execute and analyze the tests.

## Performance Test Summary (Results and Findings)

### Executive Summary

This performance test assessed the Squid proxy service's ability to handle various loads and user scenarios using Locust. The tests included load testing, stress testing, and endurance testing. The results showed that the Squid proxy service meets the expected performance criteria under normal and peak loads but showed signs of degradation under extreme stress conditions. Key issues identified include increased response times and occasional timeouts under maximum load. Recommendations for optimization include enhancing resource allocation and tuning Squid configurations for better performance.

### Test Summary

#### Load Testing
- **Average Load:** 
  - **Requests per second:** 100
  - **Average Response Time:** 150ms
  - **Error Rate:** 0.5%
- **Peak Load:** 
  - **Requests per second:** 200
  - **Average Response Time:** 300ms
  - **Error Rate:** 1.2%

#### Stress Testing
- **Maximum Load:**
  - **Requests per second:** 500
  - **Average Response Time:** 750ms
  - **Error Rate:** 5%

#### Endurance Testing
- **Sustained Load:**
  - **Duration:** 4 hours
  - **Average Requests per second:** 150
  - **Average Response Time:** 200ms
  - **Error Rate:** 0.7%

Overall, the Squid proxy service performed well under typical and peak load conditions but encountered performance issues under extreme stress scenarios.

### Issues and Recommendations

**Issues:**
1. Increased response times under maximum load.
2. Occasional timeouts under stress conditions.

**Recommendations:**
1. Optimize Squid configuration for better performance under high load.
2. Increase resource allocation (CPU, memory) to the Squid proxy instances.
3. Implement monitoring and auto-scaling to handle peak loads effectively.

## Application Overview

The Squid proxy service provides secure and efficient access to the bank's GCP cloud platform from on-premises locations. It handles incoming requests, provides caching, and enforces access controls. The service is deployed on Google Compute Managed Instance Groups, ensuring scalability and reliability.

## Performance Testing Scope

### Key Business Use-cases

| Use Case                   | Description                                                                 | Comments                     |
|----------------------------|-----------------------------------------------------------------------------|------------------------------|
| User Access to Cloud       | Users access cloud services through Squid proxy                             | Critical for user operations |
| API Requests Forwarding    | Forwarding API requests to cloud services                                   | High volume, high importance |
| Resource Caching           | Caching frequently accessed resources                                       | Improves performance         |

### Performance Testing Acceptance Criteria

- **Business Capacity:** Ensure the Squid proxy can support business operations by handling up to 200 requests per second with an average response time under 300ms. This capacity should meet the needs of daily operations and peak usage scenarios.
- **Technical Capacity:** The service should scale automatically to manage peak loads up to 500 requests per second, ensuring uninterrupted access to cloud resources during high-demand periods.
- **Exceptions:** Brief performance degradation is acceptable during extreme load tests (above 400 requests per second), provided it does not significantly impact overall user experience or business operations.

### Application Workload Volumes

| Load Type | Volume        | Performance Test Results                                             |
|-----------|---------------|-----------------------------------------------------------------------|
| Low       | 50 req/sec    | Response Time: 100ms, Error Rate: 0.1%                                |
| Average   | 100 req/sec   | Response Time: 150ms, Error Rate: 0.5%                                |
| Peak      | 200 req/sec   | Response Time: 300ms, Error Rate: 1.2%                                |
| Stress    | 500 req/sec   | Response Time: 750ms, Error Rate: 5%, occasional timeouts observed    |

## Conclusion

The Squid proxy service generally meets performance expectations under normal and peak operating conditions, ensuring reliable access to the bank's GCP cloud platform. Some performance issues were identified under extreme load scenarios, which can be mitigated through recommended optimizations. Regular monitoring and scaling strategies should be implemented to ensure consistent performance and support business continuity.
