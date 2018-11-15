resource "aws_vpc_endpoint" "ptfe_service" {
  vpc_id            = "${data.aws_vpc.main.id}"
  service_name      = "${var.ptfe_service}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.ptfe_service.id}",
  ]

  subnet_ids = ["${data.aws_subnet_ids.main.ids}"]
}

resource "aws_route53_record" "ptfe_service" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "ptfe.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.ptfe_service.dns_entry[0], "dns_name")}"]
}

resource "aws_security_group" "ptfe_service" {
  name        = "ptfe_service"
  description = "ptfe_service"
  vpc_id      = "${data.aws_vpc.main.id}"
}

resource "aws_security_group_rule" "ingress_80" {
  security_group_id        = "${aws_security_group.ptfe_service.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "80"
  to_port                  = "80"
  source_security_group_id = "${data.aws_security_group.default_security_group.id}"
}
