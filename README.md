# Deploy C8000v on AWS

## Overview

This repository sets up the C8000v in controller mode (SD-WAN mode) on AWS using Terraform.

For more information on bootstrap file used to instantiate the C8000v, read this [doc](./docs/C8000v-bootstrap.md)

## Get Catalyst 8000v parameters

Get a free UUID and token from SD-WAN Manager (Go to Configuration > Certificates > WAN Edges)

Copy `config_example.yaml` to `config.yaml`.

Fill in parameters in `config.yaml`.

## Instantiate C8000v on AWS

Change to `aws` folder and execute:

```shell
terraform init
terraform plan
terraform apply -auto-approve
```
