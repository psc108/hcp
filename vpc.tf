resource "aws_vpc" "proxy-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_eip" "sh_eip" {
  depends_on = [aws_internet_gateway.proxy-igw]
  domain     = "vpc"
  tags = {
    Name = "nat eip"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.proxy-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "proxy-subnet-1"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id                  = aws_vpc.proxy-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "proxy-subnet-2"
  }
}

resource "aws_subnet" "subnet-3" {
  vpc_id     = aws_vpc.proxy-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "proxy-subnet-3"
  }
}

resource "aws_internet_gateway" "proxy-igw" {
  vpc_id = aws_vpc.proxy-vpc.id
  tags = {
    Name = "proxy-igw"
  }
}

resource "aws_route_table" "proxy-rt" {
  vpc_id = aws_vpc.proxy-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proxy-igw.id
  }
  tags = {
    Name = "proxy-route-table"
  }
}

resource "aws_route_table_association" "proxy-rta-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.proxy-rt.id
}

resource "aws_route_table_association" "proxy-rta-2" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.proxy-rt.id
}

resource "aws_route_table_association" "proxy-rta-3" {
  subnet_id      = aws_subnet.subnet-3.id
  route_table_id = aws_route_table.proxy-rt.id
}