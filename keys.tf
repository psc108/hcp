# ec2 access keys for the proxy hosts
resource "tls_private_key" "asg-ec2-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "asg-ec2-key" {
  name                    = "asg-ec2-key.pem"
  recovery_window_in_days = 0
}

resource "aws_key_pair" "asg-ec2-key" {
  key_name   = "asg-ec2-key"
  public_key = tls_private_key.asg-ec2-key.public_key_openssh
}

resource "local_sensitive_file" "asg-ec2-key-pem-file" {
  filename             = "asg-ec2-key.pem"
  file_permission      = "400"
  directory_permission = "700"
  content              = tls_private_key.asg-ec2-key.private_key_pem
}

resource "aws_secretsmanager_secret_version" "asg-ec2-key" {
  secret_id     = aws_secretsmanager_secret.asg-ec2-key.id
  secret_string = tls_private_key.asg-ec2-key.private_key_pem
}

resource "aws_kms_key" "asg-kms-key" {
  description             = "symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "asg-key-alias" {
  name          = "alias/asg-key-alias"
  target_key_id = aws_kms_key.asg-kms-key.key_id
  depends_on = [aws_kms_key.asg-kms-key]
}

resource "aws_kms_key" "eks_encryption" {
  description         = "KMS key for EKS cluster encryption"
  policy              = data.aws_iam_policy_document.kms_key_policy.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "eks_encryption" {
  name          = "alias/eks/${var.cluster-name}"
  target_key_id = aws_kms_key.eks_encryption.id
}

/*
resource "aws_acm_certificate" "alb-certificate" {
  private_key = file("private.key")
  certificate_body = file("actual_cert.cer")
  certificate_chain = file("inter.cer")
}
 */