terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7"
    }
  }
}
