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

# route table - public
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route-table"
  }
}

# route table - private
resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route-table"
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
    Name = "route-table"
  }
}

# route table associations - public
# we only have one route table for public and only (at this time) one public route table
# the route table availability zone is set in all three eu-west-2 zones though)
resource "aws_route_table" "private" {
  for_each = local.azs
  vpc_id   = aws_vpc.main.id

  tags = {
    Name        = "${local.ws}-private-0${each.key + 1}-routes"
    Project     = "Secure Cloud"
    Environment = local.ws
  }
}

resource "aws_route_table" "public" {
  for_each = local.azs
  vpc_id   = aws_vpc.main.id

  tags = {
    Name        = "${local.ws}-public-0${each.key + 1}-routes"
    Project     = "Secure Cloud"
    Environment = local.ws
  }
}

# vpc ssm resources
resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = local.services
  vpc_id   = aws_vpc.main.id
  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_https.id]
  private_dns_enabled = true
  ip_address_type     = "ipv4"
}

resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}