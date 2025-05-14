resource "aws_vpc" "main" {
  cidr_block       = local.env.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "main"
  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw"
  }
}

# route table - private
resource "aws_route_table" "rt-efs" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "efs-route-table"
  }
}

# this will let the bastion server in/out for updates - installs etc
resource "aws_route_table_association" "rta-public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "rta-private" {
  count = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_eip" "nat_eip" { # Replace with your VPC ID
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id  = aws_eip.nat_eip.id
  subnet_id      = aws_subnet.public.id
}

# 2. Public Subnet Route Table and Route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # Assuming you have an IGW
  }
}

# 3. Private Subnet Route Table and Route
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}
