resource "aws_s3_bucket" "state_logs" {
  #checkov:skip=CKV_AWS_18:This is itself the access-log bucket — logging it would be circular
  #checkov:skip=CKV_AWS_21:Access logs are write-once and expire after 30 days; versioning would only double storage cost
  #checkov:skip=CKV_AWS_145:Access logs aren't sensitive; SSE-S3 (AES256) is sufficient, KMS adds cost
  #checkov:skip=CKV_AWS_144:Cross-region replication unnecessary for 30-day-retained access logs
  #checkov:skip=CKV2_AWS_62:No event-notification consumer for this bucket
  bucket = "haiau68-terraform-state-logs-128104558019"
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.state_logs.id
  target_prefix = "state-access-logs/"

  # S3 validates the target bucket's log-delivery permission when logging is
  # enabled, so the delivery policy must be applied first.
  depends_on = [aws_s3_bucket_policy.state_logs]
}

resource "aws_s3_bucket_public_access_block" "state_logs" {
  bucket                  = aws_s3_bucket.state_logs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    id     = "expire-logs-after-30-days"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ServerAccessLogs"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.state_logs.arn}/*"
        Condition = {
          ArnLike      = { "aws:SourceArn" = aws_s3_bucket.terraform_state.arn }
          StringEquals = { "aws:SourceAccount" = "128104558019" }
        }
      },
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.state_logs.arn, "${aws_s3_bucket.state_logs.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}
