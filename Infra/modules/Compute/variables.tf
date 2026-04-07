variable "name_prefix" {
  description = "ProjectName + Environment which actually comes in and flows in from the root module"
  type        = string
}

variable "alb_sg_id" {
  description = "SG ID coming in from security module for ALB SG"
  type        = string
}

variable "public_subnet_ids" {
  description = "The public subnet ID in which our ECS Fargate cluster is running"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID that will flow in from the Networking module"
  type        = string
}

variable "repository_url" {
  description = "The repository URL where the image is stored"
  type        = string
}

variable "environment" {
  description = "The environment of deployment (For container ENV)"
  type        = string
}

variable "aws_region" {
  description = "Region of AWS deployment (For container ENV)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private IP subnets"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "AWS ECS SG created in Security Module"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS Queue ARN to be obtained from Database module"
  type        = string
}

variable "db_secret_arn" {
  description = "Database's secret manager secret folders ARN to be obtained from Database module"
  type        = string
}

variable "sqs_queue_url" {
  description = "AWS SQS queue URL exposed from Database Module to be obtained"
  type        = string
}