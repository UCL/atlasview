#!/bin/sh

## Source the environment variables and run playbook
source .env_ansible && ansible-playbook playbook.yml -i ./hosts.yml "$@"
