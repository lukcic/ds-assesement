module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_cidr
  networks = [
    for az in var.az_list : {
      name     = az
      new_bits = 8
    }
  ]
}

resource "aws_vpc" "elasticsearch_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.project_env}-vpc"
  }
}

resource "aws_subnet" "elasticsearch_private_subnet" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id                  = aws_vpc.elasticsearch_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.project_env}-private_subnet-${each.key}"
  }
}

resource "aws_subnet" "elasticsearch_public_subnet" {
  vpc_id                  = aws_vpc.elasticsearch_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az_list[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.project_env}-public_subnet"
  }
}

resource "aws_internet_gateway" "elasticsearch_internet_gateway" {
  vpc_id = aws_vpc.elasticsearch_vpc.id
  tags = {
    Name = "${var.project_name}-${var.project_env}-internet_gateway"
  }
}

resource "aws_eip" "elasticsearch_nat_eip" {
  depends_on = [aws_internet_gateway.elasticsearch_internet_gateway]
  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway-eip"
  }
}

resource "aws_nat_gateway" "elasticsearch_nat_gateway" {
  allocation_id = aws_eip.elasticsearch_nat_eip.id
  subnet_id     = aws_subnet.elasticsearch_public_subnet.id

  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway"
  }
}

resource "aws_route_table" "elasticsearch_private_route_table" {
  vpc_id = aws_vpc.elasticsearch_vpc.id

  tags = {
    Name = "${var.project_name}-${var.project_env}-private-route_table"
  }
}

resource "aws_route_table" "elasticsearch_public_route_table" {
  vpc_id = aws_vpc.elasticsearch_vpc.id

  tags = {
    Name = "${var.project_name}-${var.project_env}-public-route_table"
  }
}

resource "aws_route" "elasticsearch_nat_gateway-route" {
  route_table_id         = aws_route_table.elasticsearch_private_route_table.id
  gateway_id             = aws_nat_gateway.elasticsearch_nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "elasticsearch_internet_gateway-route" {
  route_table_id         = aws_route_table.elasticsearch_public_route_table.id
  gateway_id             = aws_internet_gateway.elasticsearch_internet_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "elasticsearch_private_route_table_assoc" {
  for_each = { for az, subnet in aws_subnet.elasticsearch_private_subnet : az => subnet.id }

  subnet_id      = each.value
  route_table_id = aws_route_table.elasticsearch_private_route_table.id
}

resource "aws_route_table_association" "elasticsearch_public_route_table_assoc" {
  subnet_id      = aws_subnet.elasticsearch_public_subnet.id
  route_table_id = aws_route_table.elasticsearch_public_route_table.id
}
