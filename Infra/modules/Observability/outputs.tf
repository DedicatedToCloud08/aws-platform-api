output "sns_topic_arn" {
  description = "AWS SNS Topic ARN"
  value       = aws_sns_topic.sns_topic.arn
}

output "sns_topic_name" {
  description = "AWS SNS Topic name"
  value       = aws_sns_topic.sns_topic.name
}