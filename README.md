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
│   │   ├── validate.yml       # fmt + validate + Checkov scan on PRs
│   │   └── infracost.yml      # cost-estimate comment on PRs
│   └── dependabot.yml         # weekly dependency updates
├── terraform/
│   ├── environments/dev/   # dev.haiau68.com
│   ├── environments/prod/  # haiau68.com
│   ├── global/             # OIDC provider + IAM roles
│   └── modules/static-website/
├── infracost.yml           # Infracost project config (dev + prod)
└── website/
```

## Environments

| | URL | Deployment |
|---|---|---|
| dev | https://dev.haiau68.com | Auto on push to `main` |
| prod | https://haiau68.com | Manual approval required |

GitHub Actions authenticates to AWS via OIDC federation — no stored secrets. Separate IAM roles per environment restrict which workflows can deploy where.

## Automation

Pull requests run `validate.yml` — Terraform fmt, validate, and a [Checkov](https://www.checkov.io/) IaC security scan — before merge. `main` is protected by a ruleset that requires both checks to pass, so every change goes through a reviewed PR.

[Infracost](https://www.infracost.io/) posts a cost-estimate comment on every PR, flagging the monthly cost impact of a change. It's informational and does not block merges.

Dependabot opens weekly PRs for GitHub Actions and the Terraform AWS provider, grouped so related bumps land together. Major provider upgrades arrive as individual PRs for manual review.

## Security

- **No stored cloud credentials** — GitHub Actions assumes scoped, per-environment IAM roles via OIDC federation; the only repo secret is a third-party Infracost API key, which grants no AWS access.
- **Private origin** — the S3 bucket is fully private (public access blocked); CloudFront reaches it via Origin Access Control, and bucket policies deny non-TLS access.
- **Encryption at rest** — all buckets use SSE-S3; the website and state buckets are versioned, and the state bucket has access logging plus lifecycle expiry of old versions.
- **Response headers** — CloudFront serves HSTS, a Content-Security-Policy, X-Content-Type-Options, frame-deny, and a Permissions-Policy.
- **IaC scanning** — Checkov runs on every PR (including a custom policy requiring `Service` + a valid `Environment` tag on all taggable resources); non-applicable findings are suppressed inline with documented justifications.
- **Tagging** — common tags (`Project`, `Service`, `Environment`, `ManagedBy`) are defined per-stack in `locals.common_tags` and applied through the module's `tags` variable. `Environment` is capitalized (`Dev`/`Prod`/`Shared`) for FinOps tags, while `var.environment` stays lowercase for resource names.
- **Supply chain** — Actions are pinned to commit SHAs; GitHub secret scanning, push protection, and Dependabot security alerts are all enabled.

## Initial Setup

Run locally once to bootstrap before GitHub Actions takes over:

```bash
cd terraform/global && terraform init && terraform apply
cd ../environments/dev && terraform init && terraform apply
cd ../environments/prod && terraform init && terraform apply
```

## Cost

~$1.67/month (Route53 $0.50 + domain ~$1.17 · CloudFront/S3/ACM ~$0)