output "alb_dns" {
  description = "The DNS of the ALB that can be used to hit the application"
  value = aws_alb.app_load_balancer.dns_name
}

output "ecs_cluster_name" {
  description = "The name of our ecs Cluster"
  value = aws_ecs_cluster.ecs_cluster.name
}