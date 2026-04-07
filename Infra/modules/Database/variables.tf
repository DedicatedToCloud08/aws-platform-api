variable "name_prefix" {
  description = "Name prefix of the project Project Name + ENV"
  type        = string
}

variable "db_username" {
  description = "DB Username for RDS data base"
  type        = string
}

variable "dbname" {
  description = "dbname"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDS list from Modeule Networking"
  type        = list(string)
}

variable "db_instance_type" {
  description = "The basic instance type for DB RDS"
  type        = string
}

variable "rds_security_group" {
  description = "RDS Security group"
  type        = string
}
