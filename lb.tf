resource "aws_lb" "asg-lb" {
  name               = "asg-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.asg-alb-sg.id]
  subnets            = [aws_subnet.subnet-1.id , aws_subnet.subnet-2.id, aws_subnet.subnet-3.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.asg-lb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg-lb-tg.arn
  }

  lifecycle { create_before_destroy=true }
}

resource "aws_security_group" "asg-alb" {
  name = "asg-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg-lb-tg" {
  name     = "asg-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.proxy-vpc.id

  # the healthcheck needs to extend the healthy_threshold as it takes longer than two minutes for an ec2 to become
  # available and the lb status for the ec2 will become unhealthy.

  health_check {
    path                = "/index.html" # may need adjusting depending on the application your running
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}
