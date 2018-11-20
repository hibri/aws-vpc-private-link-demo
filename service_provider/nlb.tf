module "service_internal_nlb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.2.0"

  name_prefix = "${var.service}-service"
  type        = "network"
  internal    = "true"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${aws_subnet.service_provider.*.id}"]

  tags {
    environment = "test"
    terraform   = "true"
  }
}

resource "aws_lb_listener" "service_frontend" {
  load_balancer_arn = "${module.service_internal_nlb.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service_frontend.arn}"
  }
}

resource "aws_lb_target_group" "service_frontend" {
  name        = "service-frontend"
  port        = 80
  protocol    = "TCP"
  vpc_id      = "${data.aws_vpc.main.id}"
  target_type = "ip"

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}
