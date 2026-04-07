# modules/database/
#  main.tf     → RDS PostgreSQL + SQS queue + Secrets Manager secret
#  variables.tf
#  outputs.tf


resource "random_password" "db_random_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_passoword" {
  name                    = "${var.name_prefix}-db-secret"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.name_prefix}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_passoword" {
  secret_id = aws_secretsmanager_secret.db_passoword.id

  secret_string = jsonencode(
    {
      username = var.db_username
      password = random_password.db_random_password.result
      host     = aws_db_instance.rds_instance.address
      dbname   = var.dbname
      port     = 5432
    }
  )
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier        = "${var.name_prefix}-rds-instance"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_type

  username            = var.db_username
  password            = random_password.db_random_password.result
  db_name             = var.dbname
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_security_group]

  # encryption at rest
  storage_encrypted = true

  publicly_accessible = false

  tags = {
    Name = "${var.name_prefix}-rds-instance"
  }
}


resource "aws_sqs_queue" "sqs_queue" {
  name                       = "${var.name_prefix}-sqs"
  message_retention_seconds  = 86400 # one day
  visibility_timeout_seconds = 50

  tags = {
    Name = "${var.name_prefix}-sqs-queue"
  }
}