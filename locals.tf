locals {
  ws              = terraform.workspace
  domain_suffix   = var.domain-name

  # decide which environment we're currently working in, staging or prod
  env             = yamldecode(file("env.${local.ws}.yaml"))

  EFS-DNS         = aws_efs_file_system.efs-install.dns_name

  # you get an error in terraform via the highlighted vpc_cidr, that's because we use the external files
  # which control staging and prod defaults. don't worry about it
  #public_cidrs    = cidrsubnets(local.env.vpc_cidr,2,1)
  #private_cidrs   = cidrsubnets(local.env.vpc_cidr,2,2)
  #efs_cidrs   = cidrsubnets(local.env.efs_cidr,2,3)
  public_cidrs    = cidrsubnets(cidrsubnet(local.env.vpc_cidr,1,0), 1, 1)
  private_cidrs   = cidrsubnets(cidrsubnet(local.env.vpc_cidr,1,1), 1, 1)
  efs_cidrs   = cidrsubnets(cidrsubnet(local.env.vpc_cidr,1,1), 1, 1)
  #efs_cidrs   = local.env.efs_cidr

  # vpc endpoint for ssm
  services = {
    "ec2messages" : {
      "name" : "com.amazonaws.${var.region}.ec2messages"
    },
    "ssm" : {
      "name" : "com.amazonaws.${var.region}.ssm"
    },
    "ssmmessages" : {
      "name" : "com.amazonaws.${var.region}.ssmmessages"
    }
  }

 azs = {
  0 = "eu-west-2a"
  1 = "eu-west-2b"
  2 = "eu-west-2c"
  }
}