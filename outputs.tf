output "lb_dns_name-proxy" {
  description = "The DNS name of the load balancer for the proxies"
  value = aws_lb.asg-lb-proxy.dns_name
}


output "efs" {
  description = "efs mount if"
  value = aws_efs_file_system.efs-install.id
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.update_asg_ip_to_dns.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.update_asg_ip_to_dns.function_name
}

output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}