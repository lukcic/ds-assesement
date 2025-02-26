resource "aws_launch_template" "elasticsearch_launch_template" {
  depends_on             = [module.aws-vpc]
  name_prefix            = "${var.project_name}-${var.project_env}-elasticsearch_node"
  image_id               = var.ami != null ? var.ami.id : data.aws_ami.debian-12.id
  instance_type          = var.node_ec2_config.instance_type
  key_name               = aws_key_pair.elasticsearch_key_pair.id
  vpc_security_group_ids = [aws_security_group.elasticsearch_main.id]
  ebs_optimized          = true

  user_data = base64encode(templatefile("${path.module}/userdata-node.sh", {
    cluster_name    = var.elasticsearch_config.cluster_name
    elastic_version = var.elasticsearch_config.elastic_version
    master_node_ips = join(",", [for az in var.az_list : module.aws-vpc.elasticsearch_master_ips[az]])
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.node_ec2_config.root_volume_size
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.elasticsearch_iam_profile.name
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }
}

resource "aws_autoscaling_group" "elasticsearch_asg" {
  vpc_zone_identifier     = module.aws-vpc.elasticsearch_subnet_ids
  desired_capacity        = var.node_ec2_config.desired_size
  max_size                = var.node_ec2_config.max_size
  min_size                = var.node_ec2_config.min_size
  default_instance_warmup = 300
  health_check_type       = "EC2" # no ALB
  placement_group         = aws_placement_group.elasticsearch_partition_group.id
  protect_from_scale_in   = false # should be enabled for PROD

  # For ES nodes we don't need quorum, scaling is a priority
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }

  launch_template {
    id      = aws_launch_template.elasticsearch_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.project_env}-data_node-asg"
    propagate_at_launch = true
  }
}
