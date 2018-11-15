data "aws_availability_zones" "available" {}

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

data "aws_security_group" "default_security_group" {
  vpc_id = "${data.aws_vpc.main.id}"

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_route53_zone" "internal" {
  name = "internal"

  vpc {
    vpc_id = "${data.aws_vpc.main.id}"
  }
}

module "frontend_internal_nlb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.2.0"

  name_prefix = "consumer-frontend"
  type        = "network"
  internal    = "true"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]

  tags {
    environment = "test"
    terraform   = "true"
  }
}

resource "aws_lb_listener" "expose_endpoint" {
  load_balancer_arn = "${module.frontend_internal_nlb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service_endpoint.arn}"
  }
}

resource "aws_lb_target_group" "service_endpoint" {
  name        = "frontend-internal-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = "${data.aws_vpc.main.id}"
  target_type = "ip"

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_target_group_attachment" "spoke_a_endpoint" {
  target_group_arn = "${aws_lb_target_group.service_endpoint.arn}"
  target_id        = "${element(data.aws_network_interface.ptfe_interfaces.*.private_ip, count.index)}"
  port             = 80
}

data "aws_network_interface" "ptfe_interfaces" {
  id = "${element(aws_vpc_endpoint.ptfe_service.network_interface_ids, count.index)}"
}
