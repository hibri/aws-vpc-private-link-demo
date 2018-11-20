provider "aws" {
  region = "us-east-1"
}

module "service_provider" {
  source   = "./service_provider"
  vpc_cidr = "10.0.0.0/16"
}

module "consumer" {
  source          = "./consumer"
  ptfe_service    = "${module.service_provider.privatelink_service_name}"
  public_key      = "${var.public_key}"
  allow_from_cidr = "${var.allow_from_cidr}"
  vpc_cidr        = "10.0.1.0/25"
}

variable "public_key" {}

variable "allow_from_cidr" {
  type = "list"
}
