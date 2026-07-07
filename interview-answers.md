# FCMB DevOps Engineer Technical Assessment

# Interview Answers

## 1. Terraform & AWS (State Management)

### Scenario:
You are working in a team of five engineers. How do you manage Terraform state to ensure no two engineers apply changes simultaneously and that the state is secure and persistent?

Terraform relies on its state file to understand which infrastructure already exists and how it maps to the configuration. In a team environment, storing the state locally can easily lead to inconsistencies because each engineer may be working with a different copy.

To avoid this, I would configure a remote backend using an Amazon S3 bucket with versioning enabled to securely store the state file. I would also use a DynamoDB table for state locking. Whenever someone runs `terraform apply`, Terraform acquires a lock in DynamoDB, preventing another engineer from making changes until the operation is complete. This prevents race conditions and state corruption.

To secure the backend, I would encrypt the S3 bucket, enable versioning for recovery, and grant access through IAM roles using the principle of least privilege. This provides a single source of truth while allowing the team to collaborate safely.

---

## 2. Kubernetes (Networking)

### Explain the difference between ClusterIP, NodePort, and LoadBalancer. In EKS, which is preferred for production?

Pods in Kubernetes are ephemeral, meaning their IP addresses can change whenever they are restarted or rescheduled. Kubernetes Services provide a stable endpoint that applications can use to communicate without depending on Pod IP addresses.

- **ClusterIP** is the default Service type and exposes an application only within the cluster. It is commonly used for communication between internal services.
- **NodePort** exposes the application on a fixed port across all worker nodes. While useful for testing or simple environments, it is generally not recommended for production.
- **LoadBalancer** provisions an external AWS Elastic Load Balancer and distributes traffic across healthy Pods.

For production workloads on Amazon EKS, I would typically use an AWS Application Load Balancer through the AWS Load Balancer Controller. This provides Layer 7 routing, TLS termination, health checks, and better scalability than exposing services directly with NodePort.

---

## 3. ArgoCD (GitOps Strategy)

Suppose someone manually changes the replica count of a Deployment from 3 to 10 using `kubectl`. How does ArgoCD react if Self-Heal is enabled? What is the difference between Self-Heal and Automated Pruning?

ArgoCD continuously compares the live Kubernetes cluster with the desired configuration stored in Git. If someone manually changes the Deployment from three replicas to ten, ArgoCD detects that the live state has drifted from Git.

If **Self-Heal** is enabled, ArgoCD automatically restores the Deployment back to three replicas because Git is treated as the source of truth.

**Automated Pruning** serves a different purpose. If a resource has been removed from Git but still exists in the cluster, ArgoCD deletes it during synchronization. In summary, Self-Heal corrects modified resources, while Automated Pruning removes resources that should no longer exist.

---

## 4. Kafka (Scaling & Reliability)

A Kafka consumer group is falling behind producers. How would you reduce consumer lag?

The first step is to identify why the lag is occurring instead of immediately scaling consumers. I would monitor consumer lag using Kafka metrics and check whether the bottleneck is caused by slow processing, insufficient partitions, network latency, or broker resource constraints.

If the number of consumers is lower than the available partitions, I would scale the consumers horizontally. If there are fewer partitions than consumers, I would increase the partition count so Kafka can distribute the workload more effectively.

I would also profile the consumer application, optimize message processing, increase batch sizes where appropriate, and ensure the brokers have sufficient CPU, memory, and disk throughput. The solution depends on the root cause rather than applying the same fix in every situation.

---

## 5. Helm (Templating)

You have one Helm chart but need different image tags, hosts, and resource limits for development, staging, and production. How would you manage this?

I would maintain a single reusable Helm chart while separating environment-specific configuration into dedicated values files such as `values-dev.yaml`, `values-staging.yaml`, and `values-prod.yaml`.

These files would define differences such as image tags, ingress hostnames, replica counts, environment variables, and resource requests or limits. During deployment I would specify the appropriate values file using the `-f` option.

This approach avoids maintaining multiple charts, reduces duplication, and ensures every environment uses the same templates while only the configuration changes.

---

## 6. GitHub Actions (Security)

How would you securely authenticate GitHub Actions to AWS without storing long-lived AWS credentials?

Instead of storing AWS access keys in GitHub Secrets, I would use GitHub Actions OpenID Connect (OIDC) together with an AWS IAM Role.

When the workflow starts, GitHub authenticates with AWS using its OIDC identity. AWS verifies that identity and issues temporary security credentials by allowing the workflow to assume the IAM role.

Because the credentials are short-lived and generated only during workflow execution, there is no need to store permanent AWS keys in GitHub. This significantly improves security while following AWS best practices.

---

## 7. Kubernetes (Resource Management)

A Pod is repeatedly entering an OOMKilled state. How would you troubleshoot and fix it?

An OOMKilled status means the container exceeded its configured memory limit. It does not necessarily mean the Kubernetes node itself ran out of memory.

I would begin by inspecting the Pod using `kubectl describe pod` to confirm the reason for termination and then use `kubectl top pod` or Prometheus metrics to review actual memory usage.

If the application genuinely requires more memory, I would increase its resource limits. Otherwise, I would investigate the application for memory leaks or inefficient memory usage. Resource requests and limits should always be based on real production metrics rather than guesswork.

---

## 8. Terraform (Refactoring)

You moved several Terraform resources into a module. Terraform now wants to destroy and recreate everything. Why does this happen, and how would you prevent it?

Terraform tracks infrastructure using resource addresses stored in the state file. Moving resources into a module changes those addresses, so Terraform assumes the old resources no longer exist and new ones need to be created.

To avoid unnecessary destruction and downtime, I would migrate the state using `terraform state mv` or a `moved` block in newer Terraform versions. This updates Terraform's state without modifying the actual infrastructure, allowing the refactoring to happen safely.

---

## 9. Kafka & Kubernetes (Storage)

Why would you deploy Kafka brokers as a StatefulSet instead of a Deployment?

Kafka brokers require stable identities and persistent storage because each broker owns specific partitions and stores messages on disk.

A StatefulSet provides predictable Pod names, stable network identities, and dedicated Persistent Volumes using `volumeClaimTemplates`. If a broker is restarted, Kubernetes reattaches the same storage, preserving the broker's data and identity.

Deployments are designed for stateless applications, so StatefulSets are the correct choice for Kafka.

---

## 10. CI/CD (Commit to Production)

Describe the flow from a developer committing code to production deployment using GitHub Actions and ArgoCD.

The process begins when a developer pushes code to GitHub.

1. GitHub Actions is triggered automatically.
2. The workflow checks out the repository.
3. Code quality checks, unit tests, and security scans are executed.
4. A Docker image is built.
5. The image is pushed to a container registry such as Amazon ECR.
6. The deployment manifests or Helm values are updated with the new image tag.
7. The updated configuration is committed back to the Git repository.
8. ArgoCD detects the Git change because Git is the source of truth.
9. ArgoCD synchronizes the Kubernetes cluster with the repository.
10. Kubernetes performs a rolling update, verifies Pod health, and gradually replaces the old Pods with the new version.

For me, **Continuous Integration** ends after the application has been built, tested, scanned, and packaged successfully. **Continuous Delivery** begins when the deployment artifacts are promoted and ArgoCD automatically deploys the approved version into Kubernetes.