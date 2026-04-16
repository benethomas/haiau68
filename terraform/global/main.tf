# OIDC provider — one per AWS account, shared across all environments
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# Dev role — can only be assumed by workflows running on the main branch
resource "aws_iam_role" "github_actions_dev" {
  name = "github-actions-haiau68-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:benethomas/haiau68:environment:development"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "haiau68"
    Environment = "dev"
  }
}

# Prod role — can only be assumed from the production GitHub Actions environment
# GitHub environments can require manual approval before a job runs
resource "aws_iam_role" "github_actions_prod" {
  name = "github-actions-haiau68-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:benethomas/haiau68:environment:production"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "haiau68"
    Environment = "prod"
  }
}

# Permissions — same for both roles
# Note: broad managed policies for learning. In production these would be
# tightly scoped custom policies listing only the specific actions needed
locals {
  github_actions_roles = [
    aws_iam_role.github_actions_dev.name,
    aws_iam_role.github_actions_prod.name
  ]

  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudFrontFullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = {
    for pair in setproduct(local.github_actions_roles, local.managed_policies) :
    "${pair[0]}-${pair[1]}" => {
      role   = pair[0]
      policy = pair[1]
    }
  }

  role       = each.value.role
  policy_arn = each.value.policy
}