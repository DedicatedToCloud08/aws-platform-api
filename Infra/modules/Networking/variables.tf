variable "cidr_block" {
  description = "CIDR Block for VPC"
  type = string
}

variable "name_prefix" {
  description = "Name Prefix combined of Project_name-Environment"
  type = string
}

variable "availibility_zones" {
  description = "LIST of availability zones you want to deploy in the subnets"
  type = list(string)
}

variable "instance_type_nat" {
  description = "Instance type to be used for NAT"
  type = string
  default = "t3.nano"
}

variable "public_key_path" {
  description = "Publick key path for NAT instance SSH access"
  type = string
}

