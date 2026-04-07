variable "name_prefix" {
  description = "The Name prefix Projectname-ENV"
  type        = string
}

variable "email" {
  description = "Email that will subscribe to the topic of SNS"
  type        = string
}

variable "ecs_service_name" {
  description = "AWS ECS Service Name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "AWS ECS Cluster Name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "AWS ALB ARN Suffix captured as output from Compute Module"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "AWS Target Group ARN Suffix captured as output from Compute Module"
  type        = string
}



