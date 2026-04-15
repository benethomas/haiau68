terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# Required for ACM certificates — CloudFront only accepts certs from us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}