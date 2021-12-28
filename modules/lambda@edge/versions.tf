terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
  }
}
