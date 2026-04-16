output "github_actions_dev_role_arn" {
  description = "IAM role ARN for GitHub Actions dev deployments"
  value       = aws_iam_role.github_actions_dev.arn
}

output "github_actions_prod_role_arn" {
  description = "IAM role ARN for GitHub Actions prod deployments"
  value       = aws_iam_role.github_actions_prod.arn
}