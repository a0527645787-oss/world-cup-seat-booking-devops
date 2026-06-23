output "instance_public_ip" {
  description = "Elastic public IP address assigned to the EC2 instance."
  value       = local.public_ip
}

output "app_url" {
  description = "Application URL through Nginx."
  value       = "http://${local.public_ip}"
}

output "grafana_url" {
  description = "Grafana URL."
  value       = "http://${local.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command for connecting to the EC2 instance."
  value       = "ssh -i <path-to-private-key> ubuntu@${local.public_ip}"
}
