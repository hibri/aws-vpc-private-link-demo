resource "aws_vpc" "service_provider" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_hostnames = true

  tags {
    Name = "service_provider_vpc"
  }
}

resource "aws_subnet" "service_provider" {
  count                   = "${local.availability_zone_count}"
  vpc_id                  = "${data.aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(data.aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone       = "${element(local.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name = "service_provider_subnet_${count.index}"
  }
}

resource "aws_subnet" "service_provider_public" {
  count                   = "${local.availability_zone_count}"
  cidr_block              = "${cidrsubnet(data.aws_vpc.main.cidr_block, 8, length(data.aws_availability_zones.available.names) + count.index)}"
  availability_zone       = "${local.availability_zones[count.index]}"
  vpc_id                  = "${data.aws_vpc.main.id}"
  map_public_ip_on_launch = true

  depends_on = ["aws_subnet.service_provider"]

  tags {
    Name = "service_provider_public_subnet_${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${data.aws_vpc.main.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${data.aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "gw" {
  count      = "${local.availability_zone_count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw" {
  count         = "${local.availability_zone_count}"
  subnet_id     = "${element(aws_subnet.service_provider_public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.gw.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count  = "${local.availability_zone_count}"
  vpc_id = "${data.aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${local.availability_zone_count}"
  subnet_id      = "${element(aws_subnet.service_provider.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
