output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.ecr.repository_url
}

output "registry_id" {
  description = "ID of your docker registry"
  value       = aws_ecr_repository.ecr.id
}

output "registry_name" {
  description = "Name of our registory"
  value       = aws_ecr_repository.ecr.name
}