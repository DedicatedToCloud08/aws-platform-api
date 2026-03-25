terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "aws-platform-terraform-state-8"
    key = "infra/terraform.tfstate"
    region = "eu-west-1"
    use_lockfile = true                # Adding this to make sure aligned with updated policies
    # dynamodb_table = "aws-platform-terraform-lock"
    encrypt = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
    Project = var.project_name
    Environment = var.environment
    ManagedBy = "terraform"
    }
  }
}