variable "region" {
  description = "Region of deployment"
  default = "eu-west-1"
  type = string
}

variable "project_name" {
  description = "Project name"
  default = "aws-platform"
  type = string

  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "environment" {
  description = "Environment used"
  type = string

  validation {
    condition = contains(["dev","prod"], var.environment)
    error_message = "This can contain only 'dev' or 'prod' no other environments are allowed"
  }
}

variable "cidr_block" {
  description = "CIDR Block for VPC"
  type = string
}

variable "availibility_zones" {
  description = "LIST of availability zones you want to deploy in the subnets"
  type = list(string)
}

variable "instance_type_nat" {
  description = "Instance type to be used for NAT"
  type = string
  default = "t3.nano"
}

variable "public_key_path" {
  description = "Publick key path for NAT instance SSH access"
  type = string
}

variable "db_username" {
  description = "Username that we want for our database"
  type = string
}

variable "dbname" {
  description = "The Database name that we want"
  type = string
}

variable "db_instance_type" {
  description = "the database instance type we want use db.t3.micro"
  type = string
  default = "db.t3.micro"
}