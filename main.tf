provider "aws" {
  region = "us-east-1"
}

module "service_provider" {
  source = "./service_provider"
}

module "consumer" {
  source          = "./consumer"
  ptfe_service    = "${module.service_provider.privatelink_service_name}"
  public_key      = "${var.public_key}"
  allow_from_cidr = "${var.allow_from_cidr}"
}

variable "public_key" {}

variable "allow_from_cidr" {}
