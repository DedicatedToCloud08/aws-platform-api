resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name_prefix}-ecs-cluster"

  setting {
    name = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "${var.name_prefix}-task-defination"
  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512

  execution_role_arn = aws_iam_role.execution_role_ecs.arn
  task_role_arn = aws_iam_role.app_comms_role.arn

  container_definitions = jsonencode([
    {
        name = "api"
        image = var.repository_url
        memory = 512
        essential = true

        portMappings = [
            {
            containerPort = 8000
            protocol = "TCP"
        }
        ]

        environment = [
            {
                name = "ENVIRONMENT", value = var.environment
            },
            {
                name = "AWS_REGION", value = var.aws_region
            },
            {
                name ="DB_SECRET_ARN", value = var.db_secret_arn
            },
            {
                name ="SQS_QUEUE_URL", value = var.sqs_queue_url
            }
        ]

        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group" = "/ecs/${var.name_prefix}-app"
                "awslogs-region" = var.aws_region
                "awslogs-stream-prefix" = "ecs"
            }
            }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/${var.name_prefix}-app"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-app-cloudwatch-log-groups"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name = "api"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  depends_on = [ aws_lb_listener.alb_listener ]

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_port = 8000
    container_name = "api"
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups =  [ var.ecs_sg_id ]
    assign_public_ip = false
  }
}