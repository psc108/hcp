resource "aws_subnet" "private" {
  count               = 3
  vpc_id              = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# only use one public subnet
resource "aws_subnet" "public" {
  vpc_id              = aws_vpc.main.id  # Replace with your VPC ID
  cidr_block          = var.public_subnet_cidrs
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"  # Add a descriptive name
  }
}