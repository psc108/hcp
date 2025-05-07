resource "aws_launch_template" "ec2_template" {
  name                                 = "ec2_template"
  image_id                             = "ami-0fbbcfb8985f9a341"
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = aws_key_pair.ec2-key.id
  instance_type                        = "t2.micro"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.name
    private_key = tls_private_key.ec2-key.private_key_pem
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  user_data                            = filebase64("script.sh")

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "asg-group" {
  name                 = "proxy-asg-group"
  vpc_zone_identifier  = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id, aws_subnet.subnet-3.id]
  wait_for_capacity_timeout = "5m"
  health_check_type    = "EC2"
  desired_capacity     = 2
  min_size             = 1
  max_size             = 3
  wait_for_elb_capacity = 1 # slows asg creation down but ensure at least one healthy instance is created
  target_group_arns    = [aws_lb_target_group.asg-lb-tg.arn]

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
}