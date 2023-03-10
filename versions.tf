terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.64.0, != 4.0.0, != 4.1.0, != 4.2.0, != 4.3.0, != 4.4.0, != 4.5.0, != 4.6.0, != 4.7.0, != 4.8.0"
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
