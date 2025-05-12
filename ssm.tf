resource "aws_iam_role" "ssm-role" {
  name = "SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm-role.name
}


# Create an SSM document to copy a file to the instance (avoids using provisioner file usage
resource "aws_ssm_document" "test-ssm-install" {
  name             = "CopyFileToInstance"
  document_type    = "Command"
  content = <<-DOC
  aws s3 cp s3://your-bucket/your-file.txt /home/ec2-user/
  DOC
}

# Use a null_resource and remote-exec provisioner to execute the SSM document
resource "null_resource" "run_ssm_document-bastion" { # for bastion
  provisioner "local-exec" {
    command     = "aws ssm send-command --instance-ids ${aws_autoscaling_group.asg-group-bastion.id} --document-name CopyFileToInstance --document-version $2"
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "run_ssm_document-proxy" { # for proxy
  provisioner "local-exec" {
    command     = "aws ssm send-command --instance-ids ${aws_autoscaling_group.asg-group-proxy.id} --document-name CopyFileToInstance --document-version $2"
    interpreter = ["bash", "-c"]
  }
}

