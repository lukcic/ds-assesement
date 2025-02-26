# DEALSUMM Elasticsearch

## Deployment of the cluster

Below you can find instructions how to deploy the project in AWS account using Terraform.

Requirements:

- Terraform v1.5.5 or greater
- AWS account with set of permissions - EC2, VPC, IAM (EC2 roles), S3, DynamoDB

### Remote state and lock

Terraform's good practice is to store TF state in remote storage e.g. AWS S3 bucket to share it across the team. Besides
state also Terraform lock ID should be stored remotely (with AWS DynamoDB) disallowing team members simultaneous
changes.

First of all, update `backend` block in `provider.tf` file with your own resource names or delete the block if you want
to store your state and lock locally.

```hcl
  backend "s3" {
    bucket         = "lukcic-homelab-terraform-state"
    key            = "ds-elasticsearch-dev"
    region         = "eu-north-1"
    dynamodb_table = "lukcic-homelab-terraform-locks"
    encrypt        = true
  }
```

#### AWS credentials

If you decided to store state remotely, you need access to these `STATE resources` - set up credentials for accessing S3 bucket: `AWS_PROFILE` or
`ACCESS_KEY` data in your shell:

```sh
export AWS_PROFILE=lukcic_dev
export AWS_DEFAULT_REGION=eu-north-1

# or:
export AWS_ACCESS_KEY_ID=AKIAIO...
export AWS_SECRET_ACCESS_KEY=wJth...
export AWS_DEFAULT_REGION=eu-north-1
```

The same credentials can be used for deploying the project. Remember, that you need proper permissions of your AWS account to deploy resources.

### Variables

You need to create `terraform.tfvars` file inside environment catalog (e.g. environment/dev/) with all project settings. Details about variables can be found in
`variables.tf` file in each environment and module. Most of them have default vales.

Example `terraform.tfvars` file:

```hcl
project_name = "ds-elasticsearch"
project_env  = "dev"

aws_profile = "lukcic_dev"
aws_region  = "eu-north-1"

vpc_cidr           = "10.10.0.0/16"
public_subnet_cidr = "10.10.200.0/24"

az_list        = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZ..."

master_ec2_config = {
  instance_type    = "t3.medium"
  root_volume_size = 30
}

node_ec2_config = {
  instance_type    = "t3.medium"
  root_volume_size = 50
  min_size         = 2
  max_size         = 5
  desired_size     = 3
}

elasticsearch_config = {
  cluster_name    = "DealSumm-dev"
  elastic_version = "8.11.1"
}
```

### Working with Terraform

1. If all above requirements have been met, initialize the terraform project:

```sh
# change directory to proper environment
cd environment/dev/

# set credentials
export AWS_PROFILE=lukcic_dev
export AWS_DEFAULT_REGION=eu-north-1

# initialize Terraform
terraform init

# create plan file
terraform plan -out tf.plan

# apply changes
terraform apply tf.plan
```

At the end, if everything went well, you should see `Apply complete...` information.

### Testing

1. Open AWS Console, go to the EC2 -> Instances.
2. Find one of Master Node instances, connect to it using `Session Manager` - all instances have SSM Agent installed and
   permissions for accessing it.
3. Change shell to bash and send cluster health check using curl:

```sh
bash
curl -s -XGET 'http://localhost:9200/_cluster/health?wait_for_status=yellow' | jq
```

You should see cluster details, so check if number of all and data nodes are equal to your settings defined in
`terraform.tfvars` file:

```sh
$ bash
ssm-user@i-0f73d2dc1350e5ab2:/usr/bin$ curl -s -XGET 'http://localhost:9200/_cluster/health?wait_for_status=yellow' | jq
{
  "cluster_name": "DealSumm-dev",
  "status": "green",
  "timed_out": false,
  "number_of_nodes": 6,
  "number_of_data_nodes": 3,
  "active_primary_shards": 0,
  "active_shards": 0,
  "relocating_shards": 0,
  "initializing_shards": 0,
  "unassigned_shards": 0,
  "delayed_unassigned_shards": 0,
  "number_of_pending_tasks": 0,
  "number_of_in_flight_fetch": 0,
  "task_max_waiting_in_queue_millis": 0,
  "active_shards_percent_as_number": 100
}
```

## Node discovery

Elasticsearch nodes discover each other by setting called `discovery.seed_hosts` which gives node a list of IPs/FQDNs of
master nodes which node can communicate with to join the cluster.

`cluster.initial_master_nodes` - informs master nodes, which IPs/FQDNs are allowed to bootsrap the cluser.

## Scaling

Scaling data nodes can be easily done by manipulating `node_ec2_config` variable. Simply change `desired_size` value.
Remember that `max_size` value must also be changed - equal or higher!

```hcl
node_ec2_config = {
  instance_type    = "t3.medium"
  root_volume_size = 8
  min_size         = 2
  max_size         = 5
  desired_size     = 3
}
```

## Improvements

1. Multiple NAT Gateways.

    In the production environment each private subnet should have separate NAT gateway. Here we're deploying only one to reduce costs (dev).

2. Enabling Xpack Security features for Elasticsearch

    For simplifying the solution we have disabled security features like authentication and access control, transmission
    encryption, etc. In production environment all of these should be enabled to follow security best practices.

3. EC2 Discovery plugin

    For larger deployments, we can use `EC2 Discovery plugin` instead providing the list of master nodes. It allows to
    discover nodes via AWS API. More details can be found: <https://www.elastic.co/guide/en/elasticsearch/plugins/current/discovery-ec2.html>
    