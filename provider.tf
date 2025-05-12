provider "aws" {
  region  = var.region
  profile = "tform-user-mfa"

  default_tags {
    tags = {
      Name  = "Proxy"
      Owner = "${local.ws}-CSO"
    }
  }
}

#terraform {
#   backend "s3" {
#     bucket         = "tform-user-terraform-state"
#     key            = "terraform.tfstate"
 #    region         = "eu-west-2"
 #    dynamodb_table = "terraform_state"
 #  }
#}
