terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Стан за замовчуванням локальний (див. ADR-0004).
  # Для командної роботи розкоментуйте remote backend (S3 + DynamoDB lock):
  #
  # backend "s3" {
  #   bucket         = "bookswap-tfstate-<account-id>"
  #   key            = "staging/terraform.tfstate"
  #   region         = "eu-central-1"
  #   dynamodb_table = "bookswap-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "bookswap"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
