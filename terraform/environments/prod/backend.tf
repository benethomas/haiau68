terraform {
  backend "s3" {
    bucket         = "haiau68-terraform-state-128104558019"
    key            = "haiau68/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    use_lockfile   = true
  }
}