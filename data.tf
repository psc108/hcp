data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

data "aws_acm_certificate" "asg-certificate-rsa_4096" {
  domain    = var.domain-name
  key_types = ["RSA_4096"]
}

data "aws_route53_zone" "pasdxcgalaxylabs" {
  name         = var.domain-name
  private_zone = false
}

# the current hosted dns zone in use
data "aws_route53_zone" "current" {
  name = "pasdxcgalaxylabs.com"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/update_asg_ip_to_dns.py"
  output_path = "${path.module}/update_asg_ip_to_dns.zip"
}

data "template_file" "public_cidrsubnet" {
  count    = 1
  template = "$${vpc_cidr}"
  vars = {
    vpc_cidr      = aws_vpc.main.cidr_block
    current_count = count.index
  }
}

data "template_file" "private_cidrsubnet" {
  count    = 3
  template = "$${vpc_cidr}"
  vars = {
    vpc_cidr      = aws_vpc.main.cidr_block
    current_count = count.index
  }
}

data "template_file" "efs_cidrsubnet" {
  count    = 1
  template = "$${vpc_cidr}"
  vars = {
    vpc_cidr      = aws_vpc.main.cidr_block
    current_count = count.index
  }
}