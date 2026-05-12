provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "agentcore-multi-agent-deployer"
      Project     = var.name
    }
  }
}

variable "name" {
  type    = string
  default = "example-workload"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "cost_center" {
  type    = string
  default = "CC0000"
}
