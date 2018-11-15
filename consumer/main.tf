data "aws_availability_zones" "available" {}

data "aws_vpc" "main" {
  id = "${aws_vpc.consumer.id}"
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"

  depends_on = ["aws_subnet.consumer_subnet"]
}

data "aws_security_group" "default_security_group" {
  vpc_id = "${data.aws_vpc.main.id}"

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_vpc" "consumer" {
  cidr_block           = "10.0.1.0/25"
  enable_dns_hostnames = true
  enable_dns_hostnames = true

  tags {
    Name = "consumer_vpc"
  }
}

resource "aws_subnet" "consumer_subnet" {
  vpc_id                  = "${data.aws_vpc.main.id}"
  cidr_block              = "10.0.1.0/25"
  map_public_ip_on_launch = true

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
