# using eks for keystone, rabbitmq and backend (frontend will be an asg attached to a load balancer

resource "aws_eks_cluster" "cso-eks" {
  name     = "cso-eks"
  role_arn = aws_iam_role.cso-eks-role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id,
      aws_subnet.private[2].id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy]
}

resource "aws_launch_template" "cso-eks-launch-template" {
  name_prefix = "cso-eks-launch-template"
  image_id    = "ami-0fbbcfb8985f9a341" # Specify your desired AMI ID
  instance_type = "t2.small"  # Specify your desired instance type
  key_name    = aws_key_pair.asg-ec2-key.key_name   # Specify your SSH keypair
}

/*
resource "aws_eks_node_group" "keystone-eks" {

  cluster_name    = aws_eks_cluster.cso-eks.name
  node_group_name = "keystone-eks"
  node_role_arn   = aws_iam_role.cso-eks-role.arn
  subnet_ids      = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
    aws_subnet.private[2].id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 2
  }

  launch_template {
    id      = aws_launch_template.cso-eks-launch-template.id
    version = "$Default"
  }

  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = ["t2.small"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 50
  force_update_version = true
}


 */
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cso-eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cso-eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cso-eks-auth.token
  #load_config_file       = false
}