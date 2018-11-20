module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.2.0"

  name_prefix = "${var.service}-service"
  type        = "application"
  internal    = "true"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${aws_subnet.service_provider.*.id}"]

  tags {
    environment = "test"
    terraform   = "true"
  }
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

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "egress"
  protocol          = "-1"
  from_port         = "0"
  to_port           = "0"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}
