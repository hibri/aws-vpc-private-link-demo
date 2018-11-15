module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "0.1.1"

  name_prefix          = "${var.service}"
  vpc_id               = "${data.aws_vpc.main.id}"
  private_subnet_ids   = "${data.aws_subnet_ids.main.ids}"
  cluster_id           = "${aws_ecs_cluster.cluster.id}"
  task_container_image = "hibri/rhubarb-frontend:latest"

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = "true"

  // port, default protocol is HTTP
  task_container_port = "8080"

  health_check {
    port = "traffic-port"
    path = "/health"
  }

  tags {
    environment = "test"
    terraform   = "true"
  }

  lb_arn = "${module.fargate_alb.arn}"
}

module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.2.0"

  name_prefix = "${var.service}-service"
  type        = "application"
  internal    = "true"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]

  tags {
    environment = "test"
    terraform   = "true"
  }
}
