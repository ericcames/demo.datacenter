output "satellite_hostname" {
  description = "Public DNS name of the Satellite instance."
  value       = aws_instance.satellite.public_dns
}

