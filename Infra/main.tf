locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "tls_certificate" "github_oidc_thumbprint" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "OIDC" {
  url = "https://token.actions.githubusercontent.com"  # This is where tokens come from
  client_id_list = [ "sts.amazonaws.com" ]               # This is for whom the tokens are
  thumbprint_list = [ data.tls_certificate.github_oidc_thumbprint.certificates[0].sha1_fingerprint ]
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRoleWithWebIdentity" ]

    principals {
      type = "Federated"
      identifiers = [ aws_iam_openid_connect_provider.OIDC.arn ]
    }
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [ "repo:DedicatedToCloud08/aws-platform-api:*" ]
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [ "sts.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "OIDC_github_actions" {
  name = "${local.name_prefix}-OIDC-Github-Actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${local.name_prefix}-policy-for-actions"
  role = aws_iam_role.OIDC_github_actions.id

  policy = jsonencode(
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECR",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECS",
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeServices",
        "ecs:RegisterTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAM",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3ForTerraformstate",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
  )
}

module "networking" {
  source = "./modules/Networking"
  cidr_block = var.cidr_block
  availibility_zones = var.availibility_zones
  instance_type_nat = var.instance_type_nat
  public_key_path = var.public_key_path
  name_prefix = local.name_prefix
}

module "ECR" {
  source = "./modules/ECR"
  name_prefix = local.name_prefix
}

module "security" {
  source = "./modules/Security"
  name_prefix = local.name_prefix
  vpc_id = module.networking.vpc_id
}

module "database" {
  source = "./modules/Database"
  name_prefix = local.name_prefix
  db_username = var.db_username
  dbname = var.dbname
  private_subnet_ids = module.networking.Subnet_id_private
  db_instance_type = var.db_instance_type
  rds_security_group = module.security.rds_sg_id
}

module "compute" {
  source = "./modules/Compute"
  name_prefix = local.name_prefix
  alb_sg_id = module.security.alb_sg_id
  public_subnet_ids = module.networking.Subnet_id_public
  vpc_id = module.networking.vpc_id
  repository_url = module.ECR.repository_url
  environment = var.environment
  aws_region = var.region
  private_subnet_ids = module.networking.Subnet_id_private
  ecs_sg_id = module.security.ecs_sg_id
  sqs_queue_arn = module.database.sqs_queue_arn
  sqs_queue_url = module.database.sqs_queue_url
  db_secret_arn = module.database.db_secret_arn
}
