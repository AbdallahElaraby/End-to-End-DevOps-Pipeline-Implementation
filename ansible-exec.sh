#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False
cd /tmp/ansible
ansible-playbook site.yaml

sleep 10

ansible-playbook site2.yaml