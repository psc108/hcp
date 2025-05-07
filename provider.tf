provider "aws" {
  region = var.region
  profile = "tform-user-mfa"
}

default_tags {
  tags = {
    Name  = "Proxy"
    Owner = "${local.ws}-CSO"
  }
}
