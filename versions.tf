terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7"
    }
  }
}
