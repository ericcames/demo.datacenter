terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.10"

  # Backend config is supplied via TF_CLI_ARGS_init in .envrc (see .envrc.example).
  # CI uses terraform init -backend=false and skips this block.
  backend "s3" {}
}

