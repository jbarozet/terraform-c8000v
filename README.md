# Deploy C8000v on AWS

## Overview

This is to instantiate C8000v in AWS.

## Installation for Python and Ansible

Setting your python virtual environment.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt --no-deps
```

And then install ansible requirements:

```bash
ansible-galaxy install -r requirements.yml
```

## Activate environment

```shell
source .venv/bin/activate
```

## Get Catalyst 8000v parameters

Get Catalyst 8000v UUID

- Get a free UUID and token from SD-WAN Manager
- Copy `config_example.yaml` to `config.yaml`
- Fill in parameters in `config.yaml`

## Generate bootstrap configuration file for C8000v

Execute:

```shell
ansible-playbook playbooks/generate_cloudinit.yml
```

## Instantiate C8000v

execute:

```shell
terraform init
terraform plan
terraform apply -auto-approve
```
