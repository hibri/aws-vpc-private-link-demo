locals {
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  availability_zone_count = "${length(local.availability_zones)}"
}

data "aws_availability_zones" "available" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.service}-cluster"
}

data "aws_vpc" "main" {
  id = "${aws_vpc.service_provider.id}"
}

data "aws_subnet_ids" "main" {
  vpc_id     = "${data.aws_vpc.main.id}"
  depends_on = ["aws_subnet.service_provider"]
}

resource "aws_vpc_endpoint_service" "endpoint_service" {
  acceptance_required        = false
  network_load_balancer_arns = ["${module.service_internal_nlb.arn}"]
  depends_on                 = ["module.service_internal_nlb"]
}
