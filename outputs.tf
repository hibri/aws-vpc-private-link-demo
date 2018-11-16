output "service_privatelink_name" {
  value = "${module.service_provider.privatelink_service_name}"
}
output "test_instance_public_dns" {
  value = "${module.consumer.test_instance_public_dns}"
}
