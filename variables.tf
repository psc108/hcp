variable "region" {
  default = "eu-west-2"
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile to be created "
  type        = string
  default     = null
}

variable "domain-name" {
  description = "cso domain.name"
  type        = string
  default     = "pasdxcgalaxylabs.com"
}

variable "efs-dns-name" {
  type        = string
  description = "The DNS name of the EFS file system."
  default     = ""
}

variable "EFS_ID" {
  type        = string
  description = "The DNS name of the EFS file system for the setup script"
  default     = ""
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR values"
  type        = any
    default   = "10.0.1.0/24"
}

  variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR values"
  default   = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "efs_subnet_cidrs" {
  description = "EFS Subnet CIDR values"
  type        = string
  default   = "10.0.5.0/24"
}

variable "hosted_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  type        = string
  default     = "Z08718292ZVQZWCGD0M1F"
}

variable "instance_name_to_dns" {
  description = "Mapping of EC2 instance names to DNS records"
  type        = map(string)
}

variable "private-subnet-cidr" {
  default = ["10.168.30.128/26", "10.168.30.192/27", "10.168.30.224/28"]
}

variable "public-subnet-cidr" {
  default = ["10.168.30.240/29"]
}

# use the following:
# count = var.create_resource ? 1 : 0
# if one (true), create the resource, if 0(false) then don't create the resource
# you can also use something like:
variable "create_resource" {
  type        = bool
  default     = false
  description = "Set to true to create a resource, false to not"
}