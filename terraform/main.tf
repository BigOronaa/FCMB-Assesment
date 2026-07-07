################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "fcmb-vpc"

  cidr = "10.0.0.0/16"

  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project     = "FCMB Assessment"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

################################################################################
# EKS
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types

      desired_size = var.desired_size
      min_size     = var.min_size
      max_size     = var.max_size
    }
  }

  tags = {
    Project     = "FCMB Assessment"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

################################################################################
# ECR
################################################################################

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.repository_name
}