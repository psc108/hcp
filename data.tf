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

data "tls_certificate" "eks" {
  url = aws_eks_cluster.cso-eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

#data "aws_eks_cluster" "cso-eks" {
#  name = "cso-eks"
#}

data "aws_eks_cluster_auth" "cso-eks-auth" {
  name = "cso-eks-auth"
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid = "Key Administrators"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:TagResource"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        data.aws_caller_identity.current.arn
      ]
    }
    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    resources = ["*"]
  }
}