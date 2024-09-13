# Deploy C8000v on AWS and Azure

## 1. Overview

This repository deploys Catalyst 8000v instances in controller mode (SD-WAN) on AWS and Azure using Terraform.

For more information on bootstrap file used to instantiate a C8000v, read this [doc](./docs/C8000v-bootstrap.md)

## 2. C8000v Deployment parameters

Copy `config_example.yaml` to `config.yaml`.

C8000v deployment parameters can be found under the `edge_instances` section in `config.yaml`.

Get a free UUID and token from SD-WAN Manager (Go to Configuration > Certificates > WAN Edges) and fill in parameters in `config.yaml` under `edge_instances`.
Add as many C8000v as you want, they will all be deployed in the same VPC and connected to the same transport and service subnets.

## 3. C8000v Cloud Image Parameters

### Find Cisco image for AWS

#### Image ID in AWS

You need to find the "**image_id**" for C8000v to add to `config.yaml`. In AWS this is essentially the Amazon Machine Image (AMI).

- Go to the [AWS Marketplace](https://aws.amazon.com/marketplace/) page
- Search for the image.
- Cisco Catalyst 8000V Edge Software
- Click on the link
- Under Pricing, click on `View Purchase Options`
- Click `Continue to Subscribe` button.
- Click `Continue to Configuration` button.
- Verify **Fulfillment Option**, **Software Version**, and **Region** values. Changing any of these can change the **AMI Id**.
- Find the **AMI Id**.

#### Image Size in AWS

The appropriate VM size for a Cisco Catalyst 8000v depends on your specific performance requirements and workload.
Refer to the Cisco documentation to select the appropriate size.
For a lab with a small deployment and lower throughput requirements, a t3.medium image would work ( 2 vCPUS, 4 GB of RAM).
A c5n.large (2 vCPUs, 5.25 GB RAM) also would work but is not in the supported image type anymore.

For more information on AWS EC2 types, check: [AWS Image Types](https://aws.amazon.com/ec2/instance-types/)

### Find Cisco Image for Azure

#### Image ID in Azure

In Azure, the concept of an "**image_id**" is a bit different from AWS. Instead of a single image ID, Azure uses a combination of parameters (urn) to specify the image for a virtual machine. These parameters are typically defined in the source_image_reference block of the azurerm_linux_virtual_machine resource. Here's how it's usually structured:

urn: `publisher:offer:sku:version`

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

You also have to accept the Azure Marketplace term so that the image can be used to create VMs:

`az vm image terms accept --urn publisher:offer:sku:version`

Example:

`az vm image terms accept --urn cisco:cisco-c8000v-byol:17_14_01a-byol:latest`

These image parameters are defined in the `source_image_reference` block of the azurerm_linux_virtual_machine resource, like below:

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

In addition to the `source_image_reference` block,
you also need to add a plan section (for images that require you to accept terms, which the case for C8000v):

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

#### Image Size in Azure

The appropriate VM size for a Cisco Catalyst 8000v depends on your specific performance requirements and workload.
Refer to the Cisco documentation to select the appropriate size.
For a lab with a small deployment and lower throughput requirements, a Standard_D2_v2 image would work (2 vCPUs, 7 GB RAM).

## 4. Security Groups

### Security Groups for AWS

AWS Security Groups require explicit rules for both inbound and outbound traffic.
The configuration provided here may be overly permissive for production environments (for example source IP is everyone which is way too permissive)
Consider tightening these rules based on your specific security requirements.

### Security Groups for Azure

Few notes:

1. Azure NSGs require explicit rules for both inbound and outbound traffic.
2. Each rule in Azure NSGs needs a priority, which determines the order of rule application.
3. The protocol field uses different values in Azure compared to AWS (e.g., "Tcp" instead of "tcp").
4. Azure uses security_rule blocks instead of separate ingress and egress blocks.
5. The ICMP rule in Azure allows all ICMP traffic, as Azure doesn't support specifying ICMP types in NSGs.

Note that this configuration maintains the same level of access as the original AWS security groups, which may be overly permissive for production environments.
Consider tightening these rules based on your specific security requirements.

## 5. Deployment of Cisco Catalyst 8000v on AWS

Change to `aws` folder.

To deploy C8000v, execute:

```shell
terraform init
terraform plan
terraform apply --auto-approve
```

To delete C8000v, execute:

```shell
terraform destroy --auto-approve
```

Next, you'll need to manually decommission the associated UUID in SD-WAN Manager. To do this, navigate to Configuration > WAN Edges, click the three-dot menu next to the instance, and select Decommission. This script does not handle deprovisioning.

## 6. Deployment of Cisco Catalyst 8000v on Azure

Change to `azure` folder.

To deploy C8000v, execute:

```shell
terraform init
terraform plan
terraform apply --auto-approve
```

To delete C8000v, execute:

```shell
terraform destroy --auto-approve
```

Next, you'll need to manually decommission the associated UUID in SD-WAN Manager. To do this, navigate to Configuration > WAN Edges, click the three-dot menu next to the instance, and select Decommission. This script does not handle deprovisioning.
