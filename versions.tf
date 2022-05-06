terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.5.0"
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
