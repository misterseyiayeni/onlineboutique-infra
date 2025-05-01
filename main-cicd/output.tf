# Outputs

output "jenkins_server_http_url" {
  description = "HTTP URL to access Jenkins server"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "Prometheus_server_http_url" {
  description = "HTTP URL to access Prometheus server"
  value       = "http://${aws_instance.Prometheus_server.public_ip}:9090"
}

output "Grafana_server_http_url" {
  description = "HTTP URL to access Grafana server"
  value       = "http://${aws_instance.Grafana_server.public_ip}:3000"
}

output "SonaQube_server_http_url" {
  description = "HTTP URL to access SonarQube server"
  value       = "http://${aws_instance.SonaQube_server.public_ip}:9000"
}
