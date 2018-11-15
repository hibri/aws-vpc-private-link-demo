output "privatelink_service_name" {
  value = "${aws_vpc_endpoint_service.endpoint_service.service_name}"
}

output "privatelink_private_dns_name" {
  value = "${aws_vpc_endpoint_service.endpoint_service.private_dns_name}"
}
