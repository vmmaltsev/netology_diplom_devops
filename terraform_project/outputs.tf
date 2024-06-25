output "cp_internal_ip" {
  description = "Internal IP address of the control plane"
  value       = yandex_compute_instance.cp.network_interface.0.ip_address
}

output "cp_external_ip" {
  description = "External IP address of the control plane"
  value       = yandex_compute_instance.cp.network_interface.0.nat_ip_address
}

output "node1_internal_ip" {
  description = "Internal IP address of worker node 1"
  value       = yandex_compute_instance.node1.network_interface.0.ip_address
}

output "node1_external_ip" {
  description = "External IP address of worker node 1"
  value       = yandex_compute_instance.node1.network_interface.0.nat_ip_address
}

output "node2_internal_ip" {
  description = "Internal IP address of worker node 2"
  value       = yandex_compute_instance.node2.network_interface.0.ip_address
}

output "node2_external_ip" {
  description = "External IP address of worker node 2"
  value       = yandex_compute_instance.node2.network_interface.0.nat_ip_address
}
