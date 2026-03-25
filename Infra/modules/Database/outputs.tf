output "RDS_db_address" {
  description = "RDS DB address which will be used to connect"
  value = aws_db_instance.rds_instance.address
}

output "db_secret_arn" {
  description = "DB secret arn which task will use to retrieve secret"
  value = aws_secretsmanager_secret.db_passoword.arn
}

output "sqs_queue_url" {
  description = "The url used by consumer and producer"
  value = aws_sqs_queue.sqs_queue.url
}

output "sqs_queue_arn" {
  description = "The ARN used for IAM permissions"
  value = aws_sqs_queue.sqs_queue.arn
}