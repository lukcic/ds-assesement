output "elasticsearch_eip" {
  description = "Public IP address of the NAT gateway."
  value       = aws_eip.elasticsearch_nat_eip.public_ip
}

output "elasticsearch_vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.elasticsearch_vpc.id
}

output "elasticsearch_subnet_id_map" {
  description = "Map of AZs with corresponding subnet IDs"
  value       = { for az, subnet in aws_subnet.elasticsearch_private_subnet : az => subnet.id }
}

output "elasticsearch_subnet_ids" {
  description = "List of subnet IDs"
  value       = values({ for az, subnet in aws_subnet.elasticsearch_private_subnet : az => subnet.id })
}


output "elasticsearch_cidr_blocks" {
  value       = values(module.subnet_addrs.network_cidr_blocks)
  description = "List of network CIDRs"
}

output "elasticsearch_master_ips" {
  description = "List of Master Nodes IPs"
  value       = { for az, scidr in module.subnet_addrs.network_cidr_blocks : az => cidrhost(scidr, 10) }
}
