output "cluster_name" {
  description = "Amazon EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Amazon EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "repository_url" {
  description = "Amazon ECR repository URL"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID hosting the EKS cluster"
  value       = module.vpc.vpc_id
}