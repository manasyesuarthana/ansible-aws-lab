# Ansible on AWS - Hands-On Lab

A complete hands-on lab for learning **Ansible** fundamentals using **AWS EC2** infrastructure provisioned with **Terraform**. This project walks through 16 progressive exercises: from basic inventory and ping tests to roles, templates, handlers, and AWS module usage.

<br />

<div align="center">
  <img src="images/banner.webp" width="80%">
</div>

<br />

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                   │
│                                                          │
│   ┌──────────────┐                                       │
│   │  Controller  │──── SSH ────┬──► web01  (CentOS)      │
│   │  (Ubuntu)    │             ├──► web02  (CentOS)      │
│   │  Ansible     │             ├──► web03  (Ubuntu)      │
│   └──────────────┘             └──► db     (CentOS)      │
│         ▲                                                │
│         │ SSH (port 22)                                  │
└─────────┼────────────────────────────────────────────────┘
          │
     Your Machine
```

| Instance   | OS     | Role              | Key Pair     |
|------------|--------|-------------------|--------------|
| controller | Ubuntu | Ansible controller| `controlkey` |
| web01      | CentOS | Web server        | `webkey`     |
| web02      | CentOS | Web server        | `webkey`     |
| web03      | Ubuntu | Web server        | `webkey`     |
| db         | CentOS | Database server   | `dbkey`      |

## Prerequisites

| Tool      | Version       | Install Guide                            |
|-----------|---------------|------------------------------------------|
| Terraform | ≥ 1.0         | https://developer.hashicorp.com/terraform/install |
| AWS CLI   | v2            | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| SSH       | any           | Pre-installed on macOS/Linux             |

---

## Quick Start

### 1. Configure AWS Credentials

Create an **IAM user** in the AWS Console with **AdministratorAccess** policy attached. Download or copy its `aws_access_key_id` and `aws_secret_access_key`.

```bash
aws configure
```

Enter the following when prompted:

```
AWS Access Key ID [None]: <your_access_key_id>
AWS Secret Access Key [None]: <your_secret_access_key>
Default region name [None]: us-east-1
Default output format [None]: json
```

### 2. Generate SSH Key Pairs

Create three SSH key pairs inside the `terraform/keys/` directory. These keys are used by Terraform to register AWS key pairs and by you to SSH into the instances.

```bash
mkdir -p terraform/keys

ssh-keygen -t ed25519 -f terraform/keys/controlkey -N "" -C "controlkey"
ssh-keygen -t ed25519 -f terraform/keys/webkey     -N "" -C "webkey"
ssh-keygen -t ed25519 -f terraform/keys/dbkey      -N "" -C "dbkey"
```

This generates six files (three private + three public):

```
terraform/keys/
├── controlkey
├── controlkey.pub
├── webkey
├── webkey.pub
├── dbkey
└── dbkey.pub
```

**Important:** Never commit private keys to Git. The `.gitignore` already excludes `keys/`.


### 3. Provision Infrastructure with Terraform

```bash
cd terraform

# initialize terraform and install providers
terraform init

# preview what will be created
terraform plan

# create the infrastructure
terraform apply
```

Type `yes` when prompted.

When `terraform apply` completes, it outputs the **public and private IP addresses** of all instances:

```
Useful outputs:

controller_public_ip  = "x.x.x.x"
controller_private_ip = "172.31.x.x"
web01_private_ip      = "172.31.x.x"
web02_private_ip      = "172.31.x.x"
web03_private_ip      = "172.31.x.x"
db_private_ip         = "172.31.x.x"
```
Run `terraform output` to retrieve this output anytime you want.

---

### 4. Connect to the Ansible Controller

SSH into the controller using its **public IP** and the `controlkey`:

```bash
ssh -i terraform/keys/controlkey ubuntu@<controller_public_ip>
```

Terraform automatically installs Ansible on the controller via the `setup_controller.sh` provisioner script, which:
- Installs Ansible from the official PPA
- Creates a local `ansible.cfg` with host key checking disabled
- Sets up a log directory at `~/logs/ansible.log`

---

### 5. Copy Keys and Inventory to the Controller

From your **local machine**, copy the SSH keys and inventory to the controller:

```bash
# copy the web and db private keys
scp -i terraform/keys/controlkey terraform/keys/webkey ubuntu@<controller_public_ip>:~/webkey
scp -i terraform/keys/controlkey terraform/keys/dbkey  ubuntu@<controller_public_ip>:~/dbkey

# set correct permissions on the controller
ssh -i terraform/keys/controlkey ubuntu@<controller_public_ip> "chmod 400 ~/webkey ~/dbkey"
```


### 6. Create the Inventory File on the Controller

On the controller, create the inventory file using the **private IP addresses** from the `terraform output`:

```bash
ssh -i terraform/keys/controlkey ubuntu@<controller_public_ip>
```

Then on the controller:

```bash
cat <<EOF > ~/inventory
all:
  hosts:
    web01:
      ansible_host: <web01_private_ip>
    web02:
      ansible_host: <web02_private_ip>
    web03:
      ansible_user: ubuntu
      ansible_host: <web03_private_ip>
    db:
      ansible_host: <db_private_ip>

  children:
    webservers:
      hosts:
        web01:
        web02:
        web03:
      vars:
        ansible_user: ec2-user
        ansible_private_key_file: webkey
    dbservers:
      hosts:
        db:
      vars:
        ansible_user: ec2-user
        ansible_private_key_file: dbkey
    dc-oregon:
      children:
        webservers:
        dbservers:
EOF
```

**Important:** Replace all `<..._private_ip>` placeholders with the actual private IPs from `terraform output`. The web servers (web01, web02) and db use CentOS (`ec2-user`), while web03 uses Ubuntu (`ubuntu` — overridden at the host level).


### 7. Verify Connectivity

```bash
ansible all -m ping
```

If everything is set up correctly, all four hosts will respond with `SUCCESS`:

```
web01 | SUCCESS => { "ping": "pong" }
web02 | SUCCESS => { "ping": "pong" }
web03 | SUCCESS => { "ping": "pong" }
db    | SUCCESS => { "ping": "pong" }
```

**The lab is ready.** You can now proceed with the [Excercises](playbooks/README.md).

## Teardown

When you're done with the lab, destroy the infrastructure to avoid AWS charges:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. This terminates all EC2 instances and removes the associated security groups and key pairs.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Permission denied (publickey)` | Ensure key permissions are `400`: `chmod 400 <keyfile>` |
| `ansible all -m ping` fails | Verify private IPs in inventory match `terraform output` |
| `Host key verification failed` | Ensure `host_key_checking=False` is set in `ansible.cfg` |
| Terraform `apply` fails | Run `terraform init` first; verify AWS credentials with `aws sts get-caller-identity` |
| `No module named PyMySQL` | The `db.yaml` playbook installs `python3-PyMySQL`: make sure it runs before DB tasks |
| `unreachable` host errors | Check that the controller's security group allows SSH to web/db security groups |
| Timeout connecting to hosts | Ensure all instances are in the same VPC and availability zone (`us-east-1a`) |