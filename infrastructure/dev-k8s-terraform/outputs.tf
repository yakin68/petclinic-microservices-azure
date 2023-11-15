output "public_ip_address-kube-master" {
  description = "public ip of the kube-master."
  value       = azurerm_public_ip.kube-master-public-ip.ip_address
}

output "public_ip_address_worker_1" {
  description = "public ip of the worker-1."
  value       = azurerm_public_ip.worker-1-public-ip.ip_address
}

output "public_ip_address_worker_2" {
  description = "public ip of the worker-2."
  value       = azurerm_public_ip.worker-2-public-ip.ip_address
}
