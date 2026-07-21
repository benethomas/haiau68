# ---------------------------------------------------------------------------
# Read-only role for `terraform plan` on pull requests.
#
# Assumable ONLY from pull_request-triggered workflows (never a branch push or
# an environment deploy) and holds no write/apply permissions — just enough
# read access for `terraform plan` to refresh state and diff. Kept separate
# from the deploy roles so PR-triggered code can never apply.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "github_actions_plan" {
  name = "github-actions-haiau68-plan"

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
            "token.actions.githubusercontent.com:sub" = "repo:benethomas/haiau68:pull_request"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "haiau68"
    Environment = "ci"
  }
}

resource "aws_iam_role_policy" "plan_read" {
  name = "terraform-plan-read"
  role = aws_iam_role.github_actions_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateRead"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::haiau68-terraform-state-128104558019/haiau68/*"
      },
      {
        Sid      = "StateList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::haiau68-terraform-state-128104558019"
      },
      {
        #checkov:skip=CKV_AWS_355:Read-only Describe/Get/List actions have no resource-level ARN support; this role cannot mutate anything
        Sid    = "ResourceRead"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "cloudfront:Get*",
          "cloudfront:List*",
          "acm:Describe*",
          "acm:List*",
          "acm:Get*",
          "route53:Get*",
          "route53:List*",
          "budgets:Describe*",
          "budgets:View*"
        ]
        Resource = "*"
      }
    ]
  })
}
