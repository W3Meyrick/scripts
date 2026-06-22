# DevOps & Platform Engineering Interview Template with Interviewer Notes

This template includes **20 DevOps & Platform Engineering interview questions** with:
- **Why they ask it**
- **Suggested answers**
- **Interviewer’s guide** *(how to evaluate candidate depth)*

---

## Level 1 — Basics (Foundational Knowledge)

---

### Q1. What is DevOps, and why is it important?
**Why they ask:** To see if you understand the purpose of DevOps.  
**Answer:**  
DevOps is a **culture and set of practices** that bring **development** and **operations** together to deliver software **faster, more reliably, and at scale**. It focuses on **automation, collaboration, and continuous improvement**.

**Interviewer’s Guide:**  
Look for clarity around **collaboration, automation, and feedback loops**. A strong candidate explains **why DevOps exists** — bridging the dev-ops gap, reducing manual work, and improving release velocity. Good candidates may also mention CI/CD, infrastructure as code, or monitoring.

---

### Q2. What is Platform Engineering, and how is it different from DevOps?
**Why they ask:** To test understanding of evolving roles.  
**Answer:**  
- **DevOps** → A culture + practices to improve delivery and collaboration.  
- **Platform Engineering** → Builds **Internal Developer Platforms (IDPs)** that provide **self-service infra, pipelines, monitoring, and tooling**.

**Interviewer’s Guide:**  
Expect candidates to recognize that **Platform Engineering operationalizes DevOps principles** by building scalable, reusable tools for developers. Look for awareness of IDPs and developer experience (DX). Senior candidates should distinguish **"doing DevOps"** vs **"enabling DevOps"**.

---

### Q3. What are CI/CD pipelines, and why do we use them?
**Why they ask:** To check basic automation understanding.  
**Answer:**  
- **CI (Continuous Integration):** Builds & tests code automatically on changes.  
- **CD (Continuous Delivery/Deployment):** Automates deployment to staging/production.  
- Tools: Jenkins, GitHub Actions, GitLab CI, ArgoCD.

**Interviewer’s Guide:**  
Look for candidates who understand **why automation matters** — reducing human error, enabling frequent releases, and improving reliability. Strong candidates may discuss pipeline stages like build, test, deploy, monitor, and rollback strategies.

---

### Q4. What is Infrastructure as Code (IaC)? Give an example.
**Why they ask:** To test modern infra knowledge.  
**Answer:**  
IaC manages infrastructure **using code** instead of manual setup.  
Example: **Terraform** can provision AWS EC2, RDS, and networking resources automatically, version-controlled in Git.

**Interviewer’s Guide:**  
Good candidates should mention **repeatability, version control, and automation**. Bonus points if they compare Terraform, Pulumi, and CloudFormation or discuss **declarative vs imperative IaC**.

---

### Q5. What is containerization, and how is it different from virtualization?
**Why they ask:** Containers are core to modern DevOps.  
**Answer:**  
- **Containerization:** Packages code + dependencies in **lightweight, isolated environments** (e.g., Docker).  
- **Virtualization:** Runs entire OS instances; heavier and slower.  
- Containers = **faster startup, less resource usage, better portability**.

**Interviewer’s Guide:**  
Expect a comparison of **VMs vs containers**. Strong candidates explain **why containers dominate cloud-native**: speed, portability, scalability, and integration with orchestrators like Kubernetes.

---

## Level 2 — Intermediate (Tools & Best Practices)

---

### Q6. What’s the difference between Docker and Kubernetes?
**Why they ask:** To test container orchestration knowledge.  
**Answer:**  
- **Docker** → Builds & runs containers.  
- **Kubernetes** → Manages container **deployment, scaling, service discovery, and failover**.

**Interviewer’s Guide:**  
Candidates should know **Docker = packaging**, **Kubernetes = orchestration**. A deeper candidate might mention Helm, service meshes, ingress controllers, and managed services like EKS, GKE, or AKS.

---

### Q7. How do you monitor applications and infrastructure in production?
**Why they ask:** Observability is critical for DevOps success.  
**Answer:**  
- **Metrics:** Prometheus, Datadog, CloudWatch  
- **Logs:** ELK, Loki  
- **Tracing:** Jaeger, OpenTelemetry  
Best practice → Combine metrics, logs, and traces for **end-to-end observability**.

**Interviewer’s Guide:**  
Good candidates discuss **alerting, dashboards, and SLO-driven monitoring**. Senior engineers might bring up **distributed tracing** and **service-level objectives** for reliability.

---

### Q8. What is a reverse proxy, and why would you use one?
**Why they ask:** To test networking fundamentals.  
**Answer:**  
A **reverse proxy** sits between clients and backend servers:  
- Distributes traffic (load balancing)  
- Terminates SSL/TLS  
- Provides caching and security  
Examples: **NGINX, Envoy, HAProxy**.

**Interviewer’s Guide:**  
Look for clarity on **performance, scalability, and security benefits**. Advanced candidates may reference API gateways (e.g., Kong, Ambassador) and service mesh integration.

---

### Q9. How do you secure secrets in a CI/CD pipeline?
**Why they ask:** Secrets handling is crucial for compliance & safety.  
**Answer:**  
- Use **HashiCorp Vault**, **AWS Secrets Manager**, or **Kubernetes Secrets**.  
- Never hardcode secrets into code or configs.  
- Enforce **RBAC** and encrypt secrets.

**Interviewer’s Guide:**  
Expect practical approaches to handling **sensitive credentials**. Stronger candidates will mention **secret rotation**, **OIDC-based authentication**, and integration with GitOps workflows.

---

### Q10. What’s the difference between Blue-Green and Canary deployments?
**Why they ask:** Tests understanding of deployment strategies.  
**Answer:**  
- **Blue-Green:** Two identical environments → flip traffic instantly.  
- **Canary:** Gradually release to a subset of users.  
Blue-Green favors **fast rollback**, Canary favors **progressive validation**.

**Interviewer’s Guide:**  
Look for candidates who can explain **trade-offs** and mention tools like **Argo Rollouts**, **Spinnaker**, or **Flagger**. Senior engineers may link this to **feature flags** and **A/B testing**.

---

## Level 3 — Advanced (Scaling, Reliability & Security)

---

### Q11. How do you handle traffic spikes in a Kubernetes cluster?
**Why they ask:** Tests dynamic scaling strategies.  
**Answer:**  
- Enable **Horizontal Pod Autoscaler (HPA)** and **Cluster Autoscaler**.  
- Implement caching (Redis/CDN).  
- Use load testing tools like **k6**.  

**Interviewer’s Guide:**  
Look for multi-layer scaling awareness: pods, nodes, DBs, and caches. Senior candidates may mention **KEDA, service meshes, and global routing**.

---

### Q12. What is an Internal Developer Platform (IDP), and why do companies adopt them?
**Why they ask:** Platform engineering trend check.  
**Answer:**  
An **IDP** provides self-service tools for developers:  
- Provision infra  
- Deploy apps  
- Access monitoring  
Examples: **Backstage, Humanitec**.

**Interviewer’s Guide:**  
Candidates should show **awareness of DX** (developer experience). Seniors should discuss **reducing cognitive load**, **standardizing infra**, and improving **deployment velocity**.

---

### Q13. What are SLOs, SLIs, and SLAs in observability?
**Why they ask:** To evaluate SRE-level maturity.  
**Answer:**  
- **SLA:** Contractual uptime guarantee (e.g., 99.9%)  
- **SLO:** Internal target (e.g., 99.95% uptime)  
- **SLI:** Actual measurement (e.g., 99.92% last 30 days).

**Interviewer’s Guide:**  
Strong candidates connect **observability** with **business reliability goals** and explain how SLOs inform **alert thresholds** and **error budgets**.

---

### Q14. How do you debug a failing microservice in production?
**Why they ask:** Troubleshooting ability is critical.  
**Answer:**  
1. Check logs  
2. Review metrics  
3. Use distributed tracing  
4. Check deployments/configs  
5. Mitigate via feature flags or rollbacks.

**Interviewer’s Guide:**  
Probe for a **systematic approach**. Seniors discuss **root cause analysis (RCA)**, tracing inter-service dependencies, and minimizing blast radius.

---

### Q15. What security best practices do you follow in cloud environments?
**Why they ask:** Cloud-native security is critical for DevOps.  
**Answer:**  
- Apply **IAM least privilege**  
- Encrypt everything  
- Use **private networking**  
- Scan for vulnerabilities with **Trivy, Snyk**.

**Interviewer’s Guide:**  
Look for candidates aware of **shared responsibility models** and who can discuss **compliance frameworks** like SOC2, GDPR, or ISO27001.

---

## Level 4 — Scenario-Based / System Design

---

### Q16. You have a CI/CD pipeline that takes 30 minutes. How would you optimize it?
**Answer:**  
- Parallelize tests  
- Cache dependencies  
- Use incremental builds  
- Switch to faster runners  
- Build **preview environments** for partial testing.

**Interviewer’s Guide:**  
Assess **problem-solving ability** and whether they know modern pipeline optimizations. Senior candidates might reference **remote caching, GitHub Actions matrix builds**, or **Bazel**.

---

### Q17. Your Kubernetes pods keep restarting. How do you investigate?
**Answer:**  
- `kubectl logs <pod>` and `kubectl describe pod`  
- Check probes, resource limits, secrets, and configs.  
- Diagnose OOMKilled and CrashLoopBackOff issues.

**Interviewer’s Guide:**  
Look for a **structured debugging process**. Strong candidates mention **node pressure, image pull failures**, and **monitoring readiness/liveness probes**.

---

### Q18. A new feature caused a 20% latency increase. What’s your debugging process?
**Answer:**  
1. Check metrics  
2. Use tracing  
3. Compare before/after performance  
4. Roll back if needed  
5. Conduct postmortem.

**Interviewer’s Guide:**  
Look for an ability to **pinpoint root causes** and **communicate trade-offs**. Top candidates connect **profiling, caching, and database tuning** into the solution.

---

### Q19. How would you design a multi-region, highly available platform?
**Answer:**  
- Use **Active-Active or Active-Passive**  
- Global load balancing  
- Cross-region database replication  
- Chaos testing.

**Interviewer’s Guide:**  
This tests **system design skills**. Senior engineers should cover **data consistency trade-offs, RTO/RPO targets**, and failover testing.

---

### Q20. How would you set up an Internal Developer Platform from scratch?
**Answer:**  
- Developer portal: **Backstage**  
- Infra provisioning: **Terraform/Crossplane**  
- GitOps deployment: **ArgoCD**  
- Observability: **Grafana + Prometheus**  
- Role-based access and self-service templates.

**Interviewer’s Guide:**  
Strong candidates outline **tooling choices, workflows, and developer enablement**. Advanced candidates discuss **onboarding automation, golden paths, and security guardrails**.

---

# How to Use This Template
- **Beginner roles (Junior DevOps / SRE I):** Focus on Q1 → Q10  
- **Mid-level roles:** Be comfortable with Q6 → Q15  
- **Senior & Platform Engineers:** Expect Q11 → Q20  


1. What happens when a systemd service fails to start — how do you troubleshoot it?

Good answer: Check systemctl status <service> for the immediate error, then journalctl -u <service> -xe for detailed logs. Look at the unit file (systemctl cat <service>) for misconfigured paths, permissions, or dependencies. Check SELinux denials with ausearch -m avc -ts recent since SELinux often blocks things silently. Verify the binary/config it depends on actually exists and has correct ownership.
2. How do file permissions and SELinux interact?

Good answer: They're independent, additive layers. Standard Unix permissions (owner/group/other, rwx) are checked first; SELinux context (type enforcement) is checked second. A file can have 777 permissions and still be denied access if its SELinux context doesn't match what the process is allowed to touch. Good engineers know to check ls -Z and ps -Z, and use semanage/restorecon rather than just disabling SELinux to "fix" access issues.
3. How do you extend an LVM logical volume that's running out of space?

Good answer: Confirm free space in the volume group with vgs/vgdisplay. Extend the logical volume with lvextend -L +<size> /dev/vgname/lvname (or -r to resize the filesystem in the same step). Then grow the filesystem with resize2fs (ext4) or xfs_growfs (XFS) if not done automatically. Bonus points if they mention checking underlying physical volumes/disk first if the VG itself is out of space.
4. Server has high load average but low CPU usage — what's going on?

Good answer: Load average includes processes waiting on I/O, not just CPU-bound ones. Check iostat and vmstat for disk wait, and ps for processes in D state (uninterruptible sleep, usually disk I/O). Common causes: slow/failing disk, NFS mount issues, or a saturated network filesystem. This question is good for separating people who actually understand load average from those who just memorized "high load = busy CPU."
5. df shows a full filesystem, but you can't find large files accounting for it. What's happening?

Good answer: Likely a deleted file that's still open by a running process — disk space isn't released until the file descriptor closes. Find it with lsof | grep deleted (or lsof +L1). Fix by restarting the offending process or, if urgent, truncating the file via its fd in /proc/<pid>/fd/. Strong candidates also mention reserved blocks (tune2fs -l) as another possible culprit on ext-based filesystems.
6. How do you patch RHEL servers for a CVE across a fleet with minimal downtime?

Good answer: Use a configuration management tool (Ansible/Satellite) to stage and roll out patches in batches rather than all at once, ideally behind a load balancer so nodes can be drained and patched one at a time. Test in a staging environment first. Snapshot or have a rollback plan (LVM snapshot, or dnf history undo). Mention dnf updateinfo or Red Hat Satellite/Insights for tracking which CVEs apply to which hosts.
