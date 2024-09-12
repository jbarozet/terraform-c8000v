# Deploy C8000v on AWS and Azure

## Overview

This repository deploys Catalyst 8000v instances in controller (SD-WAN) mode on AWS using Terraform.

For more information on bootstrap file used to instantiate the C8000v, read this [doc](./docs/C8000v-bootstrap.md)

## Get Catalyst 8000v parameters

Copy `config_example.yaml` to `config.yaml`.

Get a free UUID and token from SD-WAN Manager (Go to Configuration > Certificates > WAN Edges)

Fill in parameters in `config.yaml`.

## Instantiate C8000v on AWS

Change to `aws` folder.

### Deploy C8000v

Execute:

```shell
terraform init
terraform plan
terraform apply --auto-approve
```

### Delete C8000v

Change to `aws` folder and execute:

```shell
terraform destroy --auto-approve
```

Next, you'll need to manually decommission the associated UUID in SD-WAN Manager. To do this, navigate to Configuration > WAN Edges, click the three-dot menu next to the instance, and select Decommission. This script does not handle deprovisioning.

## Deployment of Cisco Catalyst 8000v on Azure

### Find Azure Cisco Images

In Azure, the concept of an "image_id" is a bit different from AWS. Instead of a single image ID, Azure uses a combination of parameters to specify the image for a virtual machine. These parameters are typically defined in the source_image_reference block of the azurerm_linux_virtual_machine resource. Here's how it's usually structured:

`publisher:offer:sku:version`

For the Cisco Catalyst 8000v, you would typically use:

- publisher: "cisco"
- offer: "cisco-c8000v-byol" (for the BYOL version)
- sku: This varies based on the specific version you want. You can list available SKUs using the Azure CLI command mentioned below
- version: Often set to "latest" to get the most recent version, but you can specify a particular version if needed.

To find the exact values for your desired Cisco image, you can use the Azure CLI command you have in your notes:

```shell
az vm image list -o table --publisher cisco --offer cisco-c8000v-byol --all
```

As an example with Cisco Catalyst 8000v 17.14.1 image:

- publisher: "cisco"
- offer: "cisco-c8000v-byol"
- sku: "17_14_01a-byol"
- version: "latest"

These parameters are defined in the `source_image_reference` block of the azurerm_linux_virtual_machine resource, like below:

```hcl
resource "azurerm_linux_virtual_machine" "c8000v" {
  // ... other configuration ...

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-c8000v-byol"
    sku       = "17_14_01a-byol"
    version   = "latest"
  }

  // ... rest of the configuration ...
}
```

In addition to the `source_image_reference` block, You also need to add a plan section:

```hcl
resource "azurerm_linux_virtual_machine" "c8000v" {
  // ... other configuration ...

  plan {
    name      = "17_14_01a-byol"  // This should match the SKU
    product   = "cisco-c8000v-byol"  // This should match the offer
    publisher = "cisco"
  }

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-c8000v-byol"
    sku       = "17_14_01a-byol"
    version   = "latest"
  }

  // ... rest of the configuration ...
}
```

In this structure:

1. The plan block is used for images that require you to accept terms, which is often the case for marketplace images like Cisco's.
2. The name in the plan block typically corresponds to the sku in the source_image_reference.
3. The product in the plan block typically corresponds to the offer in the source_image_reference.
4. The publisher should be the same in both blocks.

Make sure these values match exactly with what's available in the Azure Marketplace for the Cisco Catalyst 8000v image you want to use.

### VM Size

The appropriate VM size for a Cisco Catalyst 8000v depends on your specific performance requirements and workload. Refer to the Cisco documentation to select the appropriate size. For a lab with a small deployment and lower throughput requirements, a Standard_D2_v2 image would work (2 vCPUs, 7 GB RAM).

### Security Groups

Few notes:

1. Azure NSGs require explicit rules for both inbound and outbound traffic.
2. Each rule in Azure NSGs needs a priority, which determines the order of rule application.
3. The protocol field uses different values in Azure compared to AWS (e.g., "Tcp" instead of "tcp").
4. Azure uses security_rule blocks instead of separate ingress and egress blocks.
5. The ICMP rule in Azure allows all ICMP traffic, as Azure doesn't support specifying ICMP types in NSGs.

Note that this configuration maintains the same level of access as the original AWS security groups, which may be overly permissive for production environments. Consider tightening these rules based on your specific security requirements.
