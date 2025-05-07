# ec2 access keys for the proxy hosts
resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "ec2-key-key" {
  name                    = "ec2-key.pem"
  recovery_window_in_days = 0
}

resource "aws_key_pair" "ec2-key" {
  key_name   = "ec2-key"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "local_sensitive_file" "ec2-key-pem-file" {
  filename             = "ec2-key.pem"
  file_permission      = "400"
  directory_permission = "700"
  content              = tls_private_key.ec2-key.private_key_pem
}

resource "aws_secretsmanager_secret_version" "ec2-key" {
  secret_id     = aws_secretsmanager_secret.ec2-key-key.id
  secret_string = tls_private_key.ec2-key.private_key_pem
}

# kms key policies/roles/permissions etc
resource "aws_kms_alias" "asg-key-alias" {
  name          = "alias/asg-key-alias"
  target_key_id = aws_kms_key.asg-kms-key.key_id
  depends_on = [aws_kms_key.asg-kms-key]
}

resource "aws_kms_key" "asg-kms-key" {
  description             = "symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_key_policy" "asg-kms-policy" {
  key_id = aws_kms_key.asg-kms-key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/tform-user",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/psc108"
            ]
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}