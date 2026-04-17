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

resource "aws_iam_policy" "github_actions" {
  name        = "github-actions-haiau68-policy"
  description = "Scoped permissions for haiau68 GitHub Actions deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::haiau68-terraform-state-128104558019/haiau68/*"
      },
      {
        Sid      = "TerraformStateList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::haiau68-terraform-state-128104558019"
      },
      {
        Sid    = "WebsiteBuckets"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketTagging",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::haiau68-website-*",
          "arn:aws:s3:::haiau68-website-*/*"
        ]
      },
      {
        Sid    = "CloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetOriginAccessControlConfig",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:TagResource",
          "cloudfront:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53ListZones"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53ChangeRecords"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/Z10252333CGP9076UYVK0"
      },
      {
        Sid    = "ACM"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate",
          "acm:ListTagsForCertificate",
          "acm:GetCertificate"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_dev" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = aws_iam_policy.github_actions.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_prod" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = aws_iam_policy.github_actions.arn
}

resource "aws_budgets_budget" "monthly" {
  name         = "haiau68-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 85
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["var.alert_email"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["var.alert_email"]
  }
}