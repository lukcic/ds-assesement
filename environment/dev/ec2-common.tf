data "aws_ami" "debian-12" {
  owners      = ["136693071363"]
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "elasticsearch_key_pair" {
  key_name   = "${var.project_name}-${var.project_env}-elasticsearch-ssh_key_pair"
  public_key = var.ssh_public_key
}

resource "aws_iam_role" "elasticsearch_iam_role" {
  name        = "${var.project_name}-${var.project_env}-elasticsearch-ssm_role"
  description = "Role for Elasticsearch ec2 instances"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "elasticsearch_iam_profile" {
  name = "${var.project_name}-${var.project_env}-elasticsearch-ec2_profile"
  role = aws_iam_role.elasticsearch_iam_role.name
}

resource "aws_iam_role_policy_attachment" "elasticsearch_ssm_policy_attach" {
  role       = aws_iam_role.elasticsearch_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "elasticsearch_main" {
  vpc_id      = module.aws-vpc.elasticsearch_vpc_id
  name_prefix = "${var.project_name}-${var.project_env}-sg"
  description = "Elasticsearch main SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress" {
  description       = "Egress to all"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elasticsearch_main.id
}

resource "aws_security_group_rule" "elasticsearch_http_traffic" {
  security_group_id        = aws_security_group.elasticsearch_main.id
  description              = "Elasticsearch HTTP traffic"
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9300
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.elasticsearch_main.id
}

resource "aws_security_group_rule" "elasticsearch_node_traffic" {
  security_group_id        = aws_security_group.elasticsearch_main.id
  description              = "Elasticsearch node to node communication"
  type                     = "ingress"
  from_port                = 9300
  to_port                  = 9400
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.elasticsearch_main.id
}

resource "aws_placement_group" "elasticsearch_partition_group" {
  name            = "${var.project_name}-${var.project_env}-es-partition"
  strategy        = "partition"
  partition_count = 3
}
