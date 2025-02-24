# DEALSUMM Elasticsearch

## Deployment of the cluster

### Remote state and lock

Terraform's good practice is to store TF state in remote storage e.g. AWS S3 bucket to share it across the team. Besides
state also Terraform lock ID should be stored remotely (with AWS DynamoDB) disallowing team members simultaneous changes.

#### AWS credentials

First you need access to these `STATE` resources - set up credentials for accessing S3 bucket: `AWS_PROFILE` or
`ACCESS_KEY` data in your shell:

```sh
export AWS_PROFILE=lukcic_dev
export AWS_DEFAULT_REGION=us-north-1

# or:
export AWS_ACCESS_KEY_ID=AKIAIO...
export AWS_SECRET_ACCESS_KEY=wJth...
export AWS_DEFAULT_REGION=us-north-1
```

The same credentials can be used to deploy project's infrastructure. For setting up minimal AWS permissions see next
paragraphs of this instruction.

#### State resources

### Variables

- project_name
- project_env
- aws_profile
- aws_region

### Working with Terraform

1. If all above requirements have been met, initialize the terraform project:

```sh
# change directory to proper environment
cd cd environment/dev/

# set credentials
export AWS_PROFILE=lukcic_dev
export AWS_DEFAULT_REGION=us-north-1

# initialize Terraform
terraform init
```

## Node discovery

## Scaling
