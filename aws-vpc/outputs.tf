output "elasticsearch_eip" {
  description = "Public IP address of the NAT gateway."
  value       = aws_eip.elasticsearch_eip.public_ip
}

output "elasticsearch_vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.elasticsearch_vpc.id
}

output "elasticsearch_subnet_id_map" {
  description = "Map of AZs with corresponding subnet IDs"
  value       = { for az, subnet in aws_subnet.elasticsearch_subnet : az => subnet.id }
}

output "elasticsearch_subnet_ids" {
  description = "List of subnet IDs"
  value       = values({ for az, subnet in aws_subnet.elasticsearch_subnet : az => subnet.id })
}


output "elasticsearch_cidr_blocks" {
  value       = values(module.subnet_addrs.network_cidr_blocks)
  description = "List of network CIDRs"
}
