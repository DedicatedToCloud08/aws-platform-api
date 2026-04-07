output "alb_dns" {
  description = "The DNS of the ALB that can be used to hit the application"
  value = aws_alb.app_load_balancer.dns_name
}

output "ecs_cluster_name" {
  description = "The name of our ecs Cluster - Cloud Watch Metrics"
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_name" {
  description = "The Service name of our ECS Cluster - Cloud Watch Metrics"
  value = aws_ecs_service.ecs_service.name

}

output "alb_arn_suffix" {
  description = "ARN Suffix of our ALB for Cloud Watch Metrics"
  value = aws_alb.app_load_balancer.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN Suffix of our target Group for Cloud Watch Metrics"
  value = aws_lb_target_group.alb_tg.arn_suffix
}