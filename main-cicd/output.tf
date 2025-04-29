# Outputs
output "jenkins_server_public_ip" {
  description = "public IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "Nexus_server_prublic_ip" {
  description = "public IP address of the Nexus server"
  value       = aws_instance.Nexus_server.public_ip
}

output "Prometheus_server_public_ip" {
  description = "public IP address of the Prometheus server"
  value       = aws_instance.Prometheus_server.public_ip
}

output "Grafana_server_prublic_ip" {
  description = "public IP address of the Grafana server"
  value       = aws_instance.Grafana_server.public_ip
}

output "SonaQube_server_public_ip" {
  description = "public IP address of the SonaQube server"
  value       = aws_instance.SonaQube_server.public_ip
}
