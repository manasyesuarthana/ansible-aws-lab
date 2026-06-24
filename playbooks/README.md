# Playbooks - Ansible Exercises

This directory contains all the Ansible playbooks, configurations, variables, templates, and roles used across the 16 lab exercises.

## Exercises that I did

### Exercise 1: Inventory & Ping Module

**Concepts:** Inventory files, `ping` module, disabling host key checking.

Test connectivity to all hosts:

```bash
ansible all -m ping
```

The `ansible.cfg` in this project disables host key checking (`host_key_checking=False`) so that first-time SSH connections don't prompt for confirmation.


### Exercise 2: Inventory Grouping

Organizing hosts into groups and nested groups.

The inventory defines three groups:
- `webservers` - web01, web02, web03
- `dbservers` - db
- `dc-oregon` - a parent group containing `webservers` and `dbservers` (group of groups)

Target a specific group:

```bash
ansible webservers -m ping
ansible dbservers -m ping
ansible dc-oregon -m ping
```


### Exercise 3: Variable Precedence

Variable priority — host-level vars override group-level vars.

Variables are defined at multiple levels:
- `group_vars/all` - applies to all hosts (lowest priority)
- `group_vars/webservers` / `group_vars/dbservers` - group-specific
- `host_vars/web01`, `host_vars/web02`, `host_vars/db` - host-specific (highest priority)

```bash
ansible-playbook vars_precedence.yaml
```

The `USERNAME` variable will resolve differently per host depending on where it's defined.

### Exercise 4: Ad Hoc Commands

Running one-off commands without playbooks.

```bash
ansible all -a "uptime"
ansible webservers -a "df -h"
ansible dbservers -m yum -a "name=wget state=present" --become
ansible all -m shell -a "cat /etc/os-release"
```

### Exercise 5: Playbooks

Writing and running playbooks, syntax checking, dry runs.

**Playbook:** `web.yaml`

Best practices before running a playbook:

```bash
# check for syntax errors
ansible-playbook web.yaml --syntax-check

# dry run (simulate without making changes)
ansible-playbook web.yaml -C

# run the playbook
ansible-playbook web.yaml
```

This playbook installs and starts `httpd` on all web servers.


### Exercise 6: More Modules & Documentation

Exploring the Ansible module index, using `ansible-doc`.

```bash
# list all available modules
ansible-doc -l

# get documentation for a specific module
ansible-doc ansible.builtin.copy
ansible-doc ansible.builtin.yum
ansible-doc ansible.builtin.service
```

### Exercise 7: Module Dependencies & Troubleshooting

Learning to debug failing tasks, understanding module dependencies.

**Playbook:** `db.yaml`

The database playbook installs MariaDB and uses `community.mysql` modules. These modules require `python3-PyMySQL` on the target host — the playbook installs it before creating the database.

```bash
ansible-playbook db.yaml
```

If tasks fail, check:
- Is the required Python library installed?
- Is the service running before trying to connect?
- Are socket paths correct for the OS?

### Exercise 8: Ansible Configuration

Ansible configuration hierarchy.

Configuration priority (highest to lowest):
1. `ANSIBLE_CONFIG` environment variable
2. `ansible.cfg` in the current directory
3. `~/.ansible.cfg` in the user's home directory
4. `/etc/ansible/ansible.cfg` (global)

View the active configuration:

```bash
ansible-config view
ansible-config dump --only-changed
```

### Exercise 9: Variables

Defining variables at multiple levels.

**Playbook:** `vars_precedence.yaml`

Ways to define variables:
1. In the playbook (`vars:` under the play)
2. In `group_vars/<group_name>` or `host_vars/<host_name>`
3. In roles (`vars/main.yaml` or `defaults/main.yaml`)
4. Via `register:` (capture task output)
5. Via command line (`-e VAR=value`)

Variable priority (highest to lowest):
1. Command line (`-e`)
2. Playbook `vars:`
3. `host_vars/<host_name>`
4. `group_vars/<group_name>` → falls back to `group_vars/all`

```bash
# this will override a variable from the command line
ansible-playbook vars_precedence.yaml -e USERNAME=admin -e COMM="CLI override"
```


### Exercise 10: Fact Variables

Automatically gathered system facts.

**Playbook:** `fact_vars.yaml`

Ansible gathers facts about each host during the `Gathering Facts` phase. These are accessible as variables.

```bash
ansible-playbook fact_vars.yaml
```

Example of some facts:
- `ansible_distribution` — OS name (e.g., `CentOS`, `Ubuntu`)
- `ansible_memory_mb.real.free` — Available RAM
- `ansible_processor[2]` — Processor model

You can disable fact gathering with `gather_facts: false` for faster execution when facts aren't needed.


### Exercise 11: Decision Making (`when`)

Conditional task execution.

**Playbook:** `provisioning.yaml`

The `when:` keyword controls whether a task runs based on a condition:

```yaml
- name: Install dependencies on CentOS
  ansible.builtin.yum:
    name: chrony
    state: present
  when: ansible_distribution == "CentOS"
```

This allows a single playbook to handle multiple OS distributions.

### Exercise 12: Loops

Iterating over lists with `loop` (or the older `with_items`).

**Playbook:** `provisioning.yaml`

```yaml
- name: Install dependencies on CentOS
  ansible.builtin.yum:
    name: "{{ item }}"
    state: present
  when: ansible_distribution == "CentOS"
  loop:
    - chrony
    - wget
    - git
    - zip
    - unzip
```

The `{{ item }}` variable represents each element in the loop list.

### Exercise 13: File, Copy & Template Modules

Managing files, copying content, and using Jinja2 templates.

**Playbooks:** `provisioning.yaml`, `files.yaml`

- **`file`** — Create directories, set permissions
- **`copy`** — Copy static files from controller to nodes
- **`template`** — Push Jinja2 templates with variable substitution

The NTP server address is stored in `group_vars/all` as `ntp_pool_address` and substituted into the chrony config templates:

```
templates/chronyconf_centos → /etc/chrony.conf
templates/chronyconf_ubuntu → /etc/chrony/sources.d/us-pools.sources
```

```bash
ansible-playbook provisioning.yaml
```

### Exercise 14: Handlers

Triggered actions that run only when notified by a changed task.

**Playbook:** `provisioning.yaml`

Handlers are defined at the end of a play and are triggered via `notify:`. They only execute if the notifying task reports a change.

```yaml
- name: Deploy ntp agent conf on CentOS
  ansible.builtin.template:
    src: ./templates/chronyconf_centos
    dest: /etc/chrony.conf
  notify:
    - Restart service on CentOS

handlers:
  - name: Restart service on CentOS
    ansible.builtin.service:
      name: chronyd
      state: restarted
```

If the template file hasn't changed, the handler **will not** run.

### Exercise 15: Roles

Structuring playbooks with reusable roles.

**Playbook:** `provision_using_roles.yaml`

A role organizes a playbook into a standard directory structure:

```
roles/post-install/
├── tasks/main.yaml       # Task definitions
├── handlers/main.yaml    # Handler definitions
├── vars/main.yaml        # Variables (high priority)
├── detaults/             # Default variables (low priority)
├── templates/            # Jinja2 templates (.j2 files)
├── files/                # Static files
└── meta/                 # Role metadata and dependencies
```

Create a new role:
```bash
ansible-galaxy init <role_name>
```

Run the role-based playbook:
```bash
ansible-playbook provision_using_roles.yaml
```

Install community roles:
```bash
ansible-galaxy install <role_name>
```

### Exercise 16: Ansible for AWS

Using Ansible's `amazon.aws` collection to manage AWS resources.

**Playbook:** `aws/basic-aws.yaml`

This playbook demonstrates:
1. Creating an EC2 key pair with `amazon.aws.ec2_key`
2. Launching an EC2 instance with `amazon.aws.ec2_instance`
3. Printing the instance's public IP

```bash
ansible-playbook aws/basic-aws.yaml
```

**Note:** Requires the `amazon.aws` collection. Install it with:
```bash
ansible-galaxy collection install amazon.aws
```
AWS credentials are read from environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
