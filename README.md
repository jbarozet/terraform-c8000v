# Deploy C8000v on AWS

## Overview

This repository deploys Catalyst 8000v instances in controller (SD-WAN) mode on AWS using Terraform.

For more information on bootstrap file used to instantiate the C8000v, read this [doc](./docs/C8000v-bootstrap.md)

## Get Catalyst 8000v parameters

Copy `config_example.yaml` to `config.yaml`.

Get a free UUID and token from SD-WAN Manager (Go to Configuration > Certificates > WAN Edges)

Fill in parameters in `config.yaml`.


## Instantiate C8000v on AWS

Change to `aws` folder and execute:

```shell
terraform init
terraform plan
terraform apply --auto-approve
```

## Delete C8000v

Change to `aws` folder and execute:

```shell
terraform destroy --auto-approve
```

Next, you'll need to manually decommission the associated UUID in SD-WAN Manager. To do this, navigate to Configuration > WAN Edges, click the three-dot menu next to the instance, and select Decommission. This script does not handle deprovisioning.
