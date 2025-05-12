resource "aws_lb" "asg-lb-proxy" {
  name               = "asg-lb-proxy"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow-tls-sg.id]
  subnets            = [aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id]

  /*
  access_logs {
    bucket  = aws_s3_bucket.asg-lb-logs.id
    prefix  = "proxy-logs"
    enabled = true
  }
  */
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.asg-lb-proxy.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg-lb-tg-80.arn
  }

  lifecycle { create_before_destroy=true }
}

# this https listener works but won't present the page(s) until http is configured for ssl
# it also uses a self signed cert until a real one is ordered
# you'll need to import the certificate into certificate manager manually (until I find a way
# to generate it and import it using terraform(i'm close)).

# generate the public/private combo using soe like:
# openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=pasdxcgalaxylabs.com"
# don't forget, you'll almost certainly need to have a real set.

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.asg-lb-proxy.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.asg-certificate-rsa_4096.arn
  depends_on        = [aws_lb_target_group.asg-lb-tg-443]

  default_action {
    target_group_arn = aws_lb_target_group.asg-lb-tg-443.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "asg-lb-tg-80" {
  name     = "asg-lb-tg-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # the healthcheck needs to extend the healthy_threshold as it takes longer than two minutes for an ec2 to become
  # available and the lb status for the ec2 will become unhealthy.

  health_check {
    path                = "/" # may need adjusting depending on the application your running
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "asg-lb-tg-443" {
  name     = "asg-lb-tg-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id

  # the healthcheck needs to extend the healthy_threshold as it takes longer than two minutes for an ec2 to become
  # available and the lb status for the ec2 will become unhealthy.

  health_check {
    path                = "/" # may need adjusting depending on the application your running
    protocol            = "HTTPS"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}