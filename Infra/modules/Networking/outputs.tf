output "vpc_id" {
  description = "VPC ID Output"
  value = aws_vpc.main.id
}

output "Subnet_id_public" {
  description = "Public subnets IDs"
  value = aws_subnet.public[*].id
}

output "Subnet_id_private" {
  description = "Private subnets IDs"
  value = aws_subnet.private[*].id
}

output "nat_instance_public_ip" {
  description = "NAT Instance Public ip for SSH"
  value = aws_instance.nat_instance.public_ip
}

output "nat_instance_id" {
  description = "NAT instance ID for debugging"
  value = aws_instance.nat_instance.id
}

