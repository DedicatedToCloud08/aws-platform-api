resource "aws_security_group" "alb_sg" {
  name        = "SG for ALB"
  description = "Allows all traffic from internet to port 80/443"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-ALB-SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "ecs_sg" {
  name        = "SG for ECS"
  description = "Allows all traffic from ALB to container port 8000 only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-ECS-SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "TCP"
    security_groups = [aws_security_group.alb_sg.id]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow ECS Tasks to converse with RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-RDS-SG"
  }
}
