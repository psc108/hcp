# NOTE
# As a reminder, for true h/a we need at least two instances running for each server
# This then gives us lee way such that if one server drops there's still another serving
# while the replacement comes up for service.
#
# The only one not to worry about is the bastion (formerly jump-server) which is hardly
# ever used so we can afford to not have a h/a environment for that.

resource "aws_launch_template" "ec2_template" {
  name                                 = "ec2_template"
  image_id                             = "ami-0fbbcfb8985f9a341"
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = aws_key_pair.asg-ec2-key.id
  instance_type                        = "t2.micro"
  vpc_security_group_ids               = [aws_security_group.allow-tls-sg.id]

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  user_data = base64encode(templatefile("ec2.sh", {
    EFS_ID  = aws_efs_file_system.efs-install.id
    EFS_MOUNT_POINT = "/efs"
    } ))

  monitoring {
    enabled = true
  }
}

resource "aws_launch_template" "bastion_template" {
  name                                 = "bastion_template"
  image_id                             = "ami-0fbbcfb8985f9a341"
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = aws_key_pair.asg-ec2-key.id
  instance_type                        = "t2.micro"
  vpc_security_group_ids               = [aws_security_group.allow-tls-sg.id]

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [var.iam_instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  # using variable to pass data to the running host, eg: the variable EFS_ID will be used in bastion.sh
  user_data = base64encode(templatefile("bastion.sh", {
    EFS_ID  = aws_efs_file_system.efs-install.id
    EFS_MOUNT_POINT = "/efs"
  } ))

  monitoring {
    enabled = true
  }
}

# note: if all instances in the asg drop (not likely they use all three availability zone
# then you end up waiting about 5 minutes for each instance to come back up.
# you might also see a "bad gateway" message when even one instance drops but, refreshing the browser
# will connect to the app again.

resource "aws_autoscaling_group" "asg-group-proxy" {
  name                 = "asg-group-proxy"
  vpc_zone_identifier = [aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id]
  wait_for_capacity_timeout = "5m"
  health_check_type    = "EC2"
  desired_capacity     = 2
  min_size             = 2
  max_size             = 3
  wait_for_elb_capacity = 1 # slows asg creation down but ensure at least one healthy instance is created
  target_group_arns    = [aws_lb_target_group.asg-lb-tg-80.arn]

  connection {

  }

  dynamic "tag"{
    for_each = {
      Name  = "proxy-server"
      Owner = "${local.ws}-CSO"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
  depends_on = [aws_lb.asg-lb-proxy, aws_efs_file_system.efs-install, aws_efs_mount_target.efs-mt]
}

resource "aws_autoscaling_group" "asg-group-bastion" {
  name                 = "asg-group-bastion"
  vpc_zone_identifier = [aws_subnet.public.id]
  wait_for_capacity_timeout = "5m"
  health_check_type    = "EC2"
  desired_capacity     = 1
  min_size             = 1
  max_size             = 1

  dynamic "tag"{
    for_each = {
      Name  = "bastion-server"
      Owner = "${local.ws}-CSO"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id = aws_launch_template.bastion_template.id
    version = "$Latest"
  }
  depends_on = [aws_efs_file_system.efs-install, aws_efs_mount_target.efs-mt]
}