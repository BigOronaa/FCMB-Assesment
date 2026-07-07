# Terraform, Helm, Docker & GitHub Actions

## Overview

This repository contains an Infrastructure as Code solution for provisioning AWS infrastructure and validating application deployment through an automated CI pipeline.

The solution provisions an Amazon EKS cluster and an Amazon ECR repository using Terraform, packages a microservice with Docker, deploys it using Helm, and validates the entire workflow with GitHub Actions.

---

## Solution Components

### Infrastructure Provisioning

Terraform is used to provision the AWS infrastructure.

The infrastructure consists of:

- Amazon VPC
- Amazon EKS Cluster
- Amazon ECR Repository

The ECR repository is implemented as a reusable Terraform module, while the VPC and EKS cluster use the official AWS Terraform modules.

### Containerization

The application is containerized using Docker and served through NGINX.

The resulting image is published to Docker Hub and later referenced during Helm validation.

### Kubernetes Deployment

The application is packaged as a Helm chart.

The chart supports configurable:

- Image repository
- Resource requests and limits
- ResourceQuota
- PodDisruptionBudget
- Ingress configuration

This allows the same chart to be reused across different environments by changing only configuration values.

### Continuous Integration

GitHub Actions is used to automate validation of both the infrastructure and application.

The workflow performs:

- Terraform formatting check
- Terraform initialization
- Terraform validation
- Terraform plan
- Docker image build
- Docker image push to Docker Hub
- Helm chart linting
- Helm dry-run installation

---

## Repository Structure

```text
.
├── .github/workflows
├── terraform
│   ├── modules
│   │   └── ecr
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── versions.tf
├── helm/microservice
├── app
├── Dockerfile
└── README.md
```

---

## Validation

### Terraform

The infrastructure configuration was validated using:

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan
```

![alt text](Images/TerraformInit.png)
![alt text](Images/Terraformplan.png)
---

### Helm

The Helm chart was validated using:

```bash
helm lint helm/microservice

helm install microservice helm/microservice \
  --dry-run=client --debug
```

![alt text](Images/helmcreate.png)
![alt text](Images/helmlint.png)

---

### Docker

The application image was built and tested locally before being pushed to Docker Hub.

```bash
docker build -t fcmb-microservice .

docker run -d -p 8080:80 fcmb-microservice
```

The container was verified by accessing the application through:

```
http://localhost:8080
```

![alt text](Images/dockerfile-build.png)
![alt text](Images/port8080.png)

---

## GitHub Actions

The CI workflow validates infrastructure changes before building and publishing the application image.

Pipeline stages:

1. Terraform Quality Gates
2. Docker Build and Push
3. Helm Validation

![alt text](Images/Passedpipeline.png)

---

## Troubleshooting

### Docker Hub Authentication

During pipeline execution the Docker authentication stage failed with:

```text
Error: Username and password required
```
![alt text](Images/failed_pipeline.png)

The workflow expected the following GitHub repository secrets:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

The Docker Hub username had initially been added as the secret name instead of the secret value, causing the workflow to receive empty credentials.

The issue was resolved by creating the correct repository secrets and using a Docker Hub Personal Access Token instead of an account password.

After updating the repository secrets, the workflow completed successfully.

---

## Security

The implementation follows a few basic security practices:

- Docker Hub authentication uses a Personal Access Token.
- AWS credentials are provided through GitHub Secrets.
- Terraform state files are excluded from version control.
- Sensitive files are ignored through `.gitignore`.

---

## Future Improvements

Possible enhancements include:

- Remote Terraform state using Amazon S3 with DynamoDB state locking.
- GitHub OIDC authentication for AWS.
- Automated deployment to Amazon EKS.
- GitOps deployment using ArgoCD.
