resource "aws_vpc" "consumer" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_hostnames = true

  tags {
    Name = "consumer_vpc"
  }
}

resource "aws_subnet" "consumer_subnet" {
  vpc_id                  = "${data.aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(data.aws_vpc.main.cidr_block, 0, count.index)}"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags {
    Name = "consumer_subnet"
  }
}

resource "aws_route53_zone" "internal" {
  name = "internal"

  vpc {
    vpc_id = "${data.aws_vpc.main.id}"
  }
}

data "aws_network_interface" "ptfe_interfaces" {
  id = "${element(aws_vpc_endpoint.ptfe_service.network_interface_ids, count.index)}"
}
