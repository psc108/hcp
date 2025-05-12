/*
resource "aws_vpc_dhcp_options" "main" {
  domain_name          = "${local.ws}.${local.domain_suffix}"
  domain_name_servers  = ["AmazonProvidedDNS"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.proxy-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

/*
resource "aws_route53_zone" "pasdxcgalaxylabs" {
  name = var.domain-name
  vpc {
    vpc_id = aws_vpc.proxy-vpc.id
  }
}
*/

resource "aws_route53_zone" "private" {
  name = "${local.ws}.${local.domain_suffix}"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

resource "aws_route53_record" "efs_ip" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "efs-ip"
  type    = "A"
  ttl     = "300"
  records = [aws_efs_mount_target.efs-mt.ip_address]
}

resource "aws_route53_record" "efs-cname" {
  zone_id = aws_route53_zone.private.zone_id
  name     = "efs-cname"
  type     = "CNAME"
  ttl      = 60
  #records  = ["${var.domain-name}"]
  records  = [aws_efs_file_system.efs-install.dns_name]
}

# dynamic updating asg's to reflect a possible new instance if one fails
resource "aws_lambda_function" "update_asg_ip_to_dns" {
  function_name = "update-asg-ip-to-dns"
  description   = "Updates Route 53 DNS records with ASG instance IPs"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "update_asg_ip_to_dns.lambda_handler"
  runtime       = "python3.10"
  filename      = "update_asg_ip_to_dns.zip"
  timeout       = 600

  environment {
    variables = {
      HOSTED_ZONE_ID  = var.hosted_zone_id
      INSTANCE_TO_DNS = jsonencode(var.instance_name_to_dns)
    }
  }
}

/*
resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "bastion"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.private_ip]
}

resource "aws_route53_record" "frontend" {
  count    = length(aws_instance.frontend)
  zone_id  = aws_route53_zone.private.zone_id
  name     = "frontend0${count.index + 1}"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.frontend[count.index].private_ip]
}

resource "aws_route53_record" "backend" {
  count    = length(aws_instance.backend)
  zone_id  = aws_route53_zone.private.zone_id
  name     = "backend0${count.index + 1}"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.backend[count.index].private_ip]
}

resource "aws_route53_record" "keystone" {
  count    = length(aws_instance.keystone)
  zone_id  = aws_route53_zone.private.zone_id
  name     = "keystone0${count.index + 1}"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.keystone[count.index].private_ip]
}

resource "aws_route53_record" "rabbitmq" {
  count    = length(aws_instance.rabbitmq)
  zone_id  = aws_route53_zone.private.zone_id
  name     = "rabbitmq0${count.index + 1}"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.rabbitmq[count.index].private_ip]
}

resource "aws_route53_record" "mysql" {
  zone_id  = aws_route53_zone.private.zone_id
  name     = "mysql"
  type     = "CNAME"
  ttl      = "300"
  records  = [aws_db_instance.main.address]
}

 */