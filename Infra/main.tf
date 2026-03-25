locals {
  name_prefix = "${var.project_name}-${var.environment}"
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
