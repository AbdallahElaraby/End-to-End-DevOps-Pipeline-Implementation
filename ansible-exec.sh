#!/bin/bash
cd /tmp/ansible
ansible-playbook site.yaml

sleep 10

ansible-playbook site2.yaml