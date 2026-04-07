output "vpc_id" {
  description = "exposing vpc id from networking module"
  value       = module.networking.vpc_id
}

output "Subnet_id_public" {
  description = "Exposing public subnet ids from networking module"
  value       = module.networking.Subnet_id_public
}

output "Subnet_id_private" {
  description = "Exposing private subnet ids from networking module"
  value       = module.networking.Subnet_id_private
}

output "nat_instance_public_ip" {
  description = "Exposing NAT instance public IP for ssh"
  value       = module.networking.nat_instance_public_ip
}

output "nat_instance_id" {
  description = "Exposing NAT instance ID"
  value       = module.networking.nat_instance_id
}

############### OUTPUTS EXPOSED FROM ECR ###########################

output "repository_url" {
  description = "Repository URL"
  value       = module.ECR.repository_url
}

output "registry_id" {
  description = "Registry ID of my ECR"
  value       = module.ECR.registry_id
}

output "registry_name" {
  description = "registry name of my ECR"
  value       = module.ECR.registry_name
}

############### OUTPUTS EXPOSED FROM Compute Module ###########################

output "alb_dns" {
  description = "The DNS of the ALB that can be used to hit the application"
  value       = module.compute.alb_dns
}

output "ecs_cluster_name" {
  description = "The name of our ecs Cluster"
  value       = module.compute.ecs_cluster_name
}

############### OUTPUTS EXPOSED FROM Database Module ###########################
output "RDS_db_address" {
  description = "RDS DB address which will be used to connect"
  value       = module.database.RDS_db_address
}

output "sqs_queue_url" {
  description = "The url used by consumer and producer"
  value       = module.database.sqs_queue_url
}

############### OUTPUTS For GITHUB ACTIONS ROLE ARN ###########################

output "github_actions_role_arnaction" {
  description = "OUTPUTS For GITHUB ACTIONS ROLE ARN"
  value       = aws_iam_role.OIDC_github_actions.arn
}


############### OUTPUTS EXPOSED FROM Database Module ###########################

output "sns_topic_arn" {
  description = "Output from Observability module"
  value       = module.Observability.sns_topic_arn
}