variable "aws_region" {
  description = "AWS region where the EC2 server will be created."
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type for the Docker host."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root disk size in GB."
  type        = number
  default     = 20
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to connect over SSH. Use your own IP address with /32."
  type        = string
}

variable "allowed_grafana_cidr" {
  description = "CIDR allowed to access Grafana on port 3000. Restrict this in real environments."
  type        = string
}

variable "allowed_prometheus_cidr" {
  description = "CIDR allowed to access Prometheus on port 9090. Leave empty to keep Prometheus closed publicly."
  type        = string
  default     = ""
}

variable "existing_key_pair_name" {
  description = "Name of an existing AWS EC2 key pair. If null, Terraform imports public_key_path as a new AWS key pair."
  type        = string
  default     = null
}

variable "public_key_path" {
  description = "Path to an SSH public key used only when existing_key_pair_name is null. Never commit the matching private key."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "existing_eip_allocation_id" {
  description = "Optional existing Elastic IP allocation ID to associate with this instance. If null, Terraform creates a new Elastic IP."
  type        = string
  default     = null
}
