resource "aws_instance" "web" {
  ami                         = "ami-013be31976ca2c322"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.consumer_subnet.id}"
  key_name                    = "${aws_key_pair.ssh_access.key_name}"
  security_groups             = ["${aws_security_group.allow_outside.id}", "${data.aws_security_group.default_security_group.id}"]

  tags {
    Name = "testinstance"
  }
}

resource "aws_key_pair" "ssh_access" {
  key_name   = "ssh_key"
  public_key = "${var.public_key}"
}

resource "aws_security_group_rule" "ingress_ssh" {
  security_group_id = "${aws_security_group.allow_outside.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "22"
  to_port           = "22"
  cidr_blocks       = ["${var.allow_from_cidr}"]
}

resource "aws_security_group_rule" "egress" {
  security_group_id = "${aws_security_group.allow_outside.id}"
  type              = "egress"
  protocol          = "-1"
  from_port         = "0"
  to_port           = "0"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "allow_outside" {
  name        = "allow_outside"
  description = "allow_outside"
  vpc_id      = "${data.aws_vpc.main.id}"
}

resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${data.aws_vpc.main.id}"

  tags {
    Name = "test-env-gw"
  }
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = "${data.aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-env-gw.id}"
  }

  tags {
    Name = "test-env-route-table"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.consumer_subnet.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}
