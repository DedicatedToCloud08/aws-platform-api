# For an IAM Role there are three building blocks that make it
# 1. Trust Policy - Which is created using a data source "aws_iam_policy_document"
# 2. Role - which is created using resource "aws_iam_role"
# 3. Policy attachment - which actually attaches permissions to do things using resource "aws_iam_role_policy_attachment"

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]

    principals {
      type = "Service"
      identifiers = [ "ecs-tasks.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "execution_role_ecs" {
  name = "${var.name_prefix}-execution-role-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.name_prefix}-execution-role-ecs"
  }
}

resource "aws_iam_role_policy_attachment" "execution_role_ecs" {
  role = aws_iam_role.execution_role_ecs.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


#### TASK ROLE For App to converse with Services #####

resource "aws_iam_role" "app_comms_role" {
  name = "${var.name_prefix}-apps-comms-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.name_prefix}-apps-comms-role"
  }
}

resource "aws_iam_role_policy" "policy_sqs_secret" {
  name = "${var.name_prefix}-sqs-secert"
  role = aws_iam_role.app_comms_role.id
  policy = jsonencode({
"Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [var.sqs_queue_arn]
    },
    {
      "Sid": "Statement2",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [var.db_secret_arn]
    }
  ]
  })
}