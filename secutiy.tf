resource "aws_security_group" "asg-alb-sg" {
  name = "asg-alb-sg"
  vpc_id      = aws_vpc.proxy-vpc.id
  description = "any comments to describe"

  ingress {
    from_port	  = 80
    to_port		  = 80
    protocol	  = "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  egress {
    from_port	  = 0
    to_port		  = 0
    protocol	  = "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow-tls" {
  name        = "allow-tls"
  description = "Allow TLS inbound traffic from the internet"
  vpc_id      = aws_vpc.proxy-vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "testing"
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-tls"
  }
}