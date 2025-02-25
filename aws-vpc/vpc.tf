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
  cidr_block = module.subnet_addrs.base_cidr_block
  tags = {
    Name = "${var.project_name}-${var.project_env}-vpc"
  }
}

resource "aws_subnet" "elasticsearch_subnet" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id            = aws_vpc.elasticsearch_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  depends_on = [aws_vpc.elasticsearch_vpc]

  tags = {
    Name = "${var.project_name}-${var.project_env}-subnet-${each.key}"
  }
}

resource "aws_eip" "elasticsearch_eip" {
  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway_eip"
  }
}

resource "aws_internet_gateway" "elasticsearch_int_gw" {
  vpc_id = aws_vpc.elasticsearch_vpc.id

  tags = {
    Name = "${var.project_name}-${var.project_env}-int_gateway"
  }
}

# In production each private subnet should have separate NAT gateway. 
# Here we're deploying only one in VPC to reduce costs (dev).
resource "aws_nat_gateway" "elasticsearch_nat_gateway" {
  connectivity_type = "public"
  allocation_id     = aws_eip.elasticsearch_eip.id
  subnet_id         = aws_subnet.elasticsearch_subnet[var.az_list[0]].id
  depends_on        = [aws_subnet.elasticsearch_subnet, aws_eip.elasticsearch_eip]

  tags = {
    Name = "${var.project_name}-${var.project_env}-nat_gateway"
  }
}

resource "aws_route_table" "elasticsearch_route_table" {
  vpc_id     = aws_vpc.elasticsearch_vpc.id
  depends_on = [aws_nat_gateway.elasticsearch_nat_gateway]

  route {
    cidr_block = module.subnet_addrs.base_cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.elasticsearch_nat_gateway.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-route_table"
  }
}

