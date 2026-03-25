data "aws_ami" "nat_instance_ami" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  filter {
    name = "state"
    values = [ "available" ]
  }
}


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.name_prefix}-VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  count = length(var.availibility_zones)
  cidr_block = cidrsubnet(var.cidr_block,8,count.index + 1)
  availability_zone = var.availibility_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-Subnet-Public-${count.index + 1}"
    Tier = "Public"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  count = length(var.availibility_zones)
  availability_zone = var.availibility_zones[count.index]
  cidr_block = cidrsubnet(var.cidr_block,8,count.index + 11)

  tags = {
    Name = "${var.name_prefix}-Subnet-private-${count.index + 1}"
    Tier = "Private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-IGW"
  }
}

resource "aws_security_group" "sg_nat" {
  name = "Security Group for NAT Instance"
  description = "Allow egrees to internet and Ingress requests from all over the VPC CIDR Range"
  vpc_id = aws_vpc.main.id
 
  # Allow all outbound to internet
   egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

# Allow all traffic from private subnets inbound
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ var.cidr_block ]
  }

  tags = {
    Name = "${var.name_prefix}-sg-nat"
  }
  }

  resource "aws_key_pair" "nat_key" {
    key_name = "${var.name_prefix}-key"
    public_key = file(var.public_key_path)
  }

  resource "aws_instance" "nat_instance" {
    ami = data.aws_ami.nat_instance_ami.id
    instance_type = var.instance_type_nat
    key_name = aws_key_pair.nat_key.key_name
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [ aws_security_group.sg_nat.id ]
    source_dest_check = false

user_data = <<-EOF
#!/bin/bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Set up iptables NAT rule
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save iptables rules so they survive reboots
service iptables save
EOF

tags = {
  Name = "${var.name_prefix}-nat-instance"
}
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}


resource "aws_route_table_association" "rt_public_association" {
  count = length(var.availibility_zones)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "rt_private_association" {
  count = length(var.availibility_zones)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.route_table_private.id
}



