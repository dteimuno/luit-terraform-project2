terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  required_version = ">=1.0.0"
  backend "s3" {
    bucket = "dtmterraform2"
    key    = "terraform.tfstate"
    region = "us-east-1"

  }
}
