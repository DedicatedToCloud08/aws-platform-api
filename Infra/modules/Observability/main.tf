resource "aws_sns_topic" "sns_topic" {
  name = "${var.name_prefix}-sns-alerts"

  tags = {
    Name = "${var.name_prefix}-sns-alerts"
  }
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol = "email"
  endpoint = var.email
}

resource "aws_cloudwatch_metric_alarm" "ECS_80_high_memory" {
  alarm_name = "${var.name_prefix}-ECS-High-Memory"
  comparison_operator = "GreaterThanThreshold"
  statistic = "Average"
  evaluation_periods = 2
  period = 60
  threshold = 80

  namespace = "AWS/ECS"
  metric_name = "MemoryUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions =  [aws_sns_topic.sns_topic.arn]
  ok_actions = [ aws_sns_topic.sns_topic.arn ]

  tags = {
    Name = "${var.name_prefix}-ECS-High-Memory"
  }
}

resource "aws_cloudwatch_metric_alarm" "ECS_80_High_utilisation" {
  alarm_name = "${var.name_prefix}-ECS-High-CPU-Utilisation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  period = 60
  threshold = 80
  statistic = "Average"

  namespace = "AWS/ECS"
  metric_name = "CPUUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [ aws_sns_topic.sns_topic.arn ]
  ok_actions = [ aws_sns_topic.sns_topic.arn ]

  tags = {
    Name = "${var.name_prefix}-ECS-High-CPU-Utilisation"
  }
}

resource "aws_cloudwatch_metric_alarm" "ALB_Errors" {
  alarm_name = "${var.name_prefix}-ALB-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  period = 60
  threshold = 10
  statistic = "Sum"

  namespace = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup = var.target_group_arn_suffix
  }

  alarm_actions = [ aws_sns_topic.sns_topic.arn ]
  ok_actions = [ aws_sns_topic.sns_topic.arn ]

  treat_missing_data = "notBreaching"

  tags = {
    Name = "${var.name_prefix}-ALB-5xx-errors"
  }
}


resource "aws_cloudwatch_metric_alarm" "ALB_Response_Time" {
  alarm_name = "${var.name_prefix}-ALB-Response-Time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  period = 60
  threshold = 2
  statistic = "Average"

  namespace = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup = var.target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [ aws_sns_topic.sns_topic.arn ]
  ok_actions = [ aws_sns_topic.sns_topic.arn ]


tags = {
  Name = "${var.name_prefix}-ALB-Response-Time"
}

}

resource "aws_cloudwatch_metric_alarm" "ECS_No_Running_Tasks" {
    alarm_name = "${var.name_prefix}-ECS-No-Running-Tasks"
    comparison_operator = "LessThanThreshold"
    threshold = 1
    evaluation_periods = 1
    period = 60
    statistic = "Average"

    namespace = "AWS/ECS"
    metric_name = "RunningTaskCount"

    dimensions = {
      ClusterName = var.ecs_cluster_name
      ServiceName = var.ecs_service_name
    }
    
    treat_missing_data = "breaching"

    alarm_actions = [ aws_sns_topic.sns_topic.arn ]
    ok_actions = [ aws_sns_topic.sns_topic.arn ]

    tags = {
      Name = "${var.name_prefix}-ECS-No-Running-Tasks"
    }

  
}

