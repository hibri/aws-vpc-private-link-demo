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
