# Terraform Infrastructure

This folder contains a basic Terraform module for creating AWS infrastructure for the World Cup seat booking DevOps project.

Terraform creates infrastructure only. It does not replace the existing GitHub Actions deployment workflow, and it does not store application secrets.

## What Terraform Creates

- AWS provider configured for `eu-north-1` by default.
- One Ubuntu EC2 instance.
- One Security Group.
- One Elastic IP association.
- Docker, Docker Compose plugin, and Git installed through `user_data.sh`.
- A clone or update of this repository at:

```text
/home/ubuntu/seat-booking-devops
```

The repository clone is only preparation. Terraform does not create `.env` and does not run the production application deployment.

## Terraform vs GitHub Actions

Terraform creates the server infrastructure:

```text
EC2 + Security Group + Elastic IP + Docker + Git
```

GitHub Actions deploys the application:

```text
Docker image -> Docker Hub -> EC2 -> Docker Compose -> Health Check
```

Keep these responsibilities separate. Terraform is useful for disaster recovery or creating another server. GitHub Actions is still the normal way to deploy the Flask application.

## SSH Key Behavior

Recommended: use an existing AWS EC2 Key Pair by name:

```hcl
existing_key_pair_name = "my-existing-aws-key"
```

When `existing_key_pair_name` is set, Terraform uses that key pair for the EC2 instance.

Optional alternative: if `existing_key_pair_name` is not set, Terraform imports a public key from:

```hcl
public_key_path = "~/.ssh/id_rsa.pub"
```

Important: Terraform never creates or outputs a private key. The matching private key must already exist on your machine and must never be committed to Git.

Using the same SSH key can allow access to multiple servers, but GitHub Actions deploys only to the host configured in the `EC2_HOST` GitHub Secret.

## Elastic IP Behavior

By default, Terraform creates a new Elastic IP and associates it with the new EC2 instance.

You can instead provide an existing Elastic IP allocation ID:

```hcl
existing_eip_allocation_id = "eipalloc-xxxxxxxxxxxxxxxxx"
```

Warning: one Elastic IP can be associated with only one EC2 instance at a time. Re-associating the existing production Elastic IP to a new server will move production traffic from the old server to the new one.

For disaster recovery, this can be useful after the new server is ready. For testing a second server, create a new Elastic IP instead.

If you create a new server with a new IP, update the GitHub Secret `EC2_HOST` to the new public IP before running the deploy workflow. If you move the existing production Elastic IP to the new server, `EC2_HOST` may not need to change.

## Security Group Rules

Inbound rules:

- SSH `22` from `var.allowed_ssh_cidr`
- HTTP `80` from `0.0.0.0/0`
- Grafana `3000` from `var.allowed_grafana_cidr`
- Prometheus `9090` from `var.allowed_prometheus_cidr` only when that variable is not empty

MySQL `3306` is not exposed publicly.

## user_data.sh

The EC2 bootstrap script installs:

- Docker
- Docker Compose plugin
- Git

It also clones this repository into `/home/ubuntu/seat-booking-devops`:

```text
https://github.com/a0527645787-oss/world-cup-seat-booking-devops.git
```

If the folder already contains a Git repository, the script runs `git pull --ff-only`. If the folder exists but is not a Git repository, it skips cloning instead of failing. The folder ownership is set to `ubuntu:ubuntu`.

The script does not create `.env`, does not include secrets, and does not run Docker Compose.

## Why This Helps Disaster Recovery

If the existing EC2 server is lost, Terraform can create a new server with the same basic infrastructure shape. After that, you can securely restore `.env` and deploy the app again with GitHub Actions or Docker Compose.

## Before You Run Terraform

Install and configure:

- Terraform
- AWS credentials
- An SSH key pair

## Example terraform.tfvars

Create `terraform.tfvars` locally. It is ignored by Git because it may contain personal IP addresses, local paths, or environment-specific values.

```hcl
allowed_ssh_cidr     = "YOUR_IP_ADDRESS/32"
allowed_grafana_cidr = "YOUR_IP_ADDRESS/32"

# Optional. Leave empty to keep Prometheus closed publicly.
allowed_prometheus_cidr = ""

# Recommended: use an existing AWS EC2 Key Pair.
existing_key_pair_name = "my-existing-aws-key"

# Optional alternative if existing_key_pair_name is not set.
public_key_path = "~/.ssh/id_rsa.pub"

# Optional. If omitted, Terraform creates a new Elastic IP.
existing_eip_allocation_id = null
```

## How To Run

From this folder:

```bash
terraform init
terraform plan
terraform apply
```

After `terraform apply`, Terraform prints:

- `instance_public_ip`
- `app_url`
- `grafana_url`
- `ssh_command`

## Manual Steps After A Fresh Server

After Terraform creates a new EC2 server:

1. SSH into the server.
2. Create `.env` securely or copy the existing production `.env` manually.
3. If this server has a new public IP, update the GitHub Secret `EC2_HOST`.
4. Run the GitHub Actions deployment workflow, or deploy manually with Docker Compose.

Manual deployment example:

```bash
cd ~/seat-booking-devops
docker compose --env-file .env -f docker-compose.prod.yml pull
docker compose --env-file .env -f docker-compose.prod.yml up -d
curl http://localhost/health
```

Use a real production `.env` file. Do not put secrets in Terraform.

## What Terraform Does Not Do

Terraform does not:

- Create a production `.env` file.
- Store secrets.
- Create or output SSH private keys.
- Run Docker Compose for the application.
- Replace the GitHub Actions deployment workflow.
