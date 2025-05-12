resource "aws_iam_role" "asg-role" {
  name = "asg-role"
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        },
                {
                    "Action": [
                        "sts:AssumeRole"
                    ],
                    "Principal": {
                        "Service": [
                            "autoscaling.amazonaws.com"
                        ]
                    },
                    "Effect": "Allow"
                }
      ]
    }
EOF
}

resource "aws_iam_policy" "asg-iam-policy" {
  name        = "asg-iam-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kms_key_policy" "asg-kms-key-policy" {
  key_id = aws_kms_key.asg-kms-key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  depends_on = [aws_kms_key.asg-kms-key]
}

resource "aws_iam_role_policy_attachment" "asg-iam-role-attach" {
  role       = aws_iam_role.asg-role.name
  policy_arn = aws_iam_policy.asg-iam-policy.arn
}

resource "aws_iam_role" "rds-monitoring-role" {
  name = "${local.ws}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Sid = ""
      }
    ]
  })
  tags = {
    Environment = local.ws
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "Lambda_update_asg_ip_to_dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole",
    }],
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "Lambda_update_asg_ip_to_dns_policy"
  description = "Permissions for Lambda to modify Route 53 and access EC2"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Action: [
          "route53:List*",
          "route53:ChangeResourceRecordSets",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID",
      },
      {
        Action   = ["ec2:DescribeInstances"],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "arn:aws:logs:*:*:*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}