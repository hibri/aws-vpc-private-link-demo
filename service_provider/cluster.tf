module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "0.1.1"

  name_prefix          = "${var.service}"
  vpc_id               = "${data.aws_vpc.main.id}"
  private_subnet_ids   = ["${aws_subnet.service_provider.*.id}"]
  cluster_id           = "${aws_ecs_cluster.cluster.id}"
  task_container_image = "hibri/rhubarb-frontend:latest"

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = "false"

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
