resource "aws_instance" "elasticsearch_master" {
  for_each   = module.aws-vpc.elasticsearch_subnet_id_map
  depends_on = [module.aws-vpc]

  instance_type          = var.master_ec2_config.instance_type
  ami                    = var.ami != null ? var.ami.id : data.aws_ami.debian-12.id
  key_name               = aws_key_pair.elasticsearch_key_pair.id
  subnet_id              = each.value
  availability_zone      = each.key
  vpc_security_group_ids = [aws_security_group.elasticsearch_main.id]
  iam_instance_profile   = aws_iam_instance_profile.elasticsearch_iam_profile.name
  placement_group        = aws_placement_group.elasticsearch_partition_group.id
  ebs_optimized          = true
  enable_primary_ipv6    = false

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  private_ip = module.aws-vpc.elasticsearch_master_ips[each.key]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = var.master_ec2_config.root_volume_size
    tags = {
      Name = "${var.project_name}-${var.project_env}-es-root_vol_${each.key}"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.project_env}-master_node-${each.key}"
  }

  user_data = templatefile("${path.module}/userdata-master.sh", {
    cluster_name    = var.elasticsearch_config.cluster_name
    elastic_version = var.elasticsearch_config.elastic_version
    master_node_ips = join(",", [for az in var.az_list : module.aws-vpc.elasticsearch_master_ips[az]])
  })

  user_data_replace_on_change = false
}
