#!/bin/bash

sudo apt update -y
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y

sudo cp /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.backup
sudo ansible-config init --disabled -t all > /etc/ansible/ansible.cfg

mkdir logs
touch logs/ansible.log

cat <<EOF > ./ansible.cfg
[defaults]
inventory=./inventory
host_key_checking=False
forks=3
log_path=./logs/ansible.log

[privilege_escalation]
become=True
become_method=sudo
become_ask_pass=False
EOF