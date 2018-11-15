data "aws_availability_zones" "available" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.service}-cluster"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}



resource "aws_lb_listener" "alb" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}

resource "aws_security_group_rule" "task_ingress_8080" {
  security_group_id        = "${module.fargate.service_sg_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "8080"
  to_port                  = "8080"
  source_security_group_id = "${module.fargate_alb.security_group_id}"
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

module "service_internal_nlb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.2.0"

  name_prefix = "${var.service}-service"
  type        = "network"
  internal    = "true"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]

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

resource "aws_vpc_endpoint_service" "endpoint_service" {
  acceptance_required        = false
  network_load_balancer_arns = ["${module.service_internal_nlb.arn}"]
}
