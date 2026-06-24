# Terraform - AWS Lab Infrastructure

This directory contains the Terraform configuration that provisions the entire AWS infrastructure for the Ansible lab.

## What gets created

| Resource             | Type                | Description                                    |
|----------------------|---------------------|------------------------------------------------|
| `ansible_controller` | EC2 Instance        | Ubuntu - Ansible controller with Ansible pre-installed |
| `web_server1`        | EC2 Instance        | CentOS - Web server (web01)                    |
| `web_server2`        | EC2 Instance        | CentOS - Web server (web02)                    |
| `web_server3`        | EC2 Instance        | Ubuntu - Web server (web03)                    |
| `db_server`          | EC2 Instance        | CentOS - Database server                       |
| `control_key`        | Key Pair            | SSH key pair for the controller                |
| `web_key`            | Key Pair            | SSH key pair for web servers                   |
| `db_key`             | Key Pair            | SSH key pair for the DB server                 |
| `controller_sg`      | Security Group      | SG for the controller instance                 |
| `web_sg`             | Security Group      | SG for web server instances                    |
| `db_sg`              | Security Group      | SG for the database instance                   |

All instances are `t2.micro` (free tier eligible) in `us-east-1a`.

## Files

| File                 | Purpose                                                      |
|----------------------|--------------------------------------------------------------|
| `provider.tf`        | AWS provider configuration (region from variable)            |
| `vars.tf`            | Input variables: region, availability zone, AMI IDs          |
| `key_pair.tf`        | Registers three SSH key pairs from `keys/` directory         |
| `instances.tf`       | Defines all five EC2 instances with provisioners             |
| `security_groups.tf` | Security groups with ingress/egress rules                    |
| `output.tf`          | Outputs public and private IPs for all instances             |
| `scripts/setup_controller.sh` | Bootstrap script that installs Ansible on the controller |
| `keys/`              | SSH key pairs (git-ignored)        |

## Variables

| Variable            | Default                                     | Description                    |
|---------------------|---------------------------------------------|--------------------------------|
| `region`            | `us-east-1`                                 | AWS region                     |
| `availability_zone` | `us-east-1a`                                | Availability zone              |
| `amiID`             | Map of controller, web, db AMIs             | AMI IDs per instance role      |

The AMI map:
- `controller` → Ubuntu AMI (`ami-0b6d9d3d33ba97d99`)
- `web` → CentOS AMI (`ami-0e0416d387552f0b1`)
- `db` → CentOS AMI (`ami-0e0416d387552f0b1`)

> **Note:** web03 uses the **controller (Ubuntu) AMI** intentionally, so the lab includes a mix of OS distributions.

## Security Groups

### Ingress Rules

| Rule                          | Security Group  | Source               | Port | Purpose                                  |
|-------------------------------|-----------------|----------------------|------|------------------------------------------|
| `myip_ssh_controller`         | controller-sg   | Your public IP /32   | 22   | SSH from your machine to controller      |
| `myip_ssh_web`                | web-sg          | Your public IP /32   | 22   | SSH from your machine to web servers     |
| `myip_ssh_db`                 | db-sg           | Your public IP /32   | 22   | SSH from your machine to DB server       |
| `controller_ssh_web`          | web-sg          | controller-sg        | 22   | SSH from controller to web servers       |
| `controller_ssh_db`           | db-sg           | controller-sg        | 22   | SSH from controller to DB server         |
| `allow_all_traffic_http_web`  | web-sg          | 0.0.0.0/0            | 80   | HTTP access to web servers               |

Your public IP is auto-detected using `https://ipv4.icanhazip.com`.

### Egress Rules

All security groups allow **all outbound traffic** (IPv4 and IPv6).

## Controller Provisioner

The controller instance runs `scripts/setup_controller.sh` on first boot via Terraform's `remote-exec` provisioner. This script:

1. Updates the package index
2. Installs Ansible from the official PPA (`ppa:ansible/ansible`)
3. Backs up and regenerates the global Ansible config
4. Creates a local `ansible.cfg` with:
   - `host_key_checking=False`
   - Inventory pointing to `./inventory`
   - Log file at `./logs/ansible.log`
   - Privilege escalation enabled via `sudo`

## Outputs

Retrieve outputs at any time:

```bash
terraform output
```

## Usage

```bash
# 1. generate SSH keys (if not already done)
mkdir -p keys
ssh-keygen -t ed25519 -f keys/controlkey -N "" -C "controlkey"
ssh-keygen -t ed25519 -f keys/webkey     -N "" -C "webkey"
ssh-keygen -t ed25519 -f keys/dbkey      -N "" -C "dbkey"

# 2. initialize and apply
terraform init
terraform plan
terraform apply

# 3. when done, tear down
terraform destroy
```
