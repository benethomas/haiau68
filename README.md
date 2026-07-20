# Hải Âu 68 — Spa & Wellness Website

Static website for [haiau68.com](https://haiau68.com) built on AWS with a fully automated CI/CD pipeline.

## Architecture

```
Visitor → CloudFront (CDN + HTTPS) → S3 (private bucket)
                 ↑
           Route53 DNS
           ACM certificate

GitHub Actions → OIDC → AWS IAM role → deploy
```

## Stack

Terraform · AWS (S3, CloudFront, ACM, Route53) · GitHub Actions · OIDC

## Repo Structure

```
├── .github/
│   ├── workflows/
│   │   ├── deploy-infra.yml   # runs on terraform/ changes
│   │   ├── deploy-site.yml    # runs on website/ changes
│   │   └── validate.yml       # fmt + validate on PRs
│   └── dependabot.yml         # weekly dependency updates
├── terraform/
│   ├── environments/dev/   # dev.haiau68.com
│   ├── environments/prod/  # haiau68.com
│   ├── global/             # OIDC provider + IAM roles
│   └── modules/static-website/
└── website/
```

## Environments

| | URL | Deployment |
|---|---|---|
| dev | https://dev.haiau68.com | Auto on push to `main` |
| prod | https://haiau68.com | Manual approval required |

GitHub Actions authenticates to AWS via OIDC federation — no stored secrets. Separate IAM roles per environment restrict which workflows can deploy where.

## Automation

Pull requests run `validate.yml` (Terraform fmt + validate) before merge. `main` is protected — all changes go through a PR.

Dependabot opens weekly PRs for GitHub Actions and the Terraform AWS provider, grouped so related bumps land together. Major provider upgrades arrive as individual PRs for manual review.

## Initial Setup

Run locally once to bootstrap before GitHub Actions takes over:

```bash
cd terraform/global && terraform init && terraform apply
cd ../environments/dev && terraform init && terraform apply
cd ../environments/prod && terraform init && terraform apply
```

## Cost

~$1.67/month (Route53 $0.50 + domain ~$1.17 · CloudFront/S3/ACM ~$0)