output "elasticsearch_eip" {
  description = "Public IP address of NAT gateway."
  value       = aws_eip.elasticsearch_eip.public_ip
}
