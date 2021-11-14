terraform {
  backend "s3" {
    bucket         = "symbiotesorg-development-s3-origin"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    # profile = "default"
  }
}