# Create and Boot Catalyst 8000v (Controller Mode) on AWS or Azure

## Introduction

2 options:

- Configuration using CLI: start your C8000v and connect to console. Cut/paste a basic day0 config. Pick a UUID/Token from the list of devices on vManage. Activate C8000v with this new UUID. This is obviously not the recommended option
- Instantiate the C8000v using bootstrap (cloud-init format). Create a bootstrap config (mime encoded). This bootstrap MUST have UUID, OTP, and all necessary parameters defined

## 1. Bootstrap File Format

### Overview

To instantiate a Catalyst 80000v in controller mode and make sure it can register to the SD-WAN controllers (Validator, Controllers and Manager), you need to create a so called day0 configuration (bootstrap configuration) and pass that day0 configuration upon bootup.

> Note: cloud-init is supported on C8000v starting from 17.8.

This day0/bootstrap configuration is a mime-encoded file that contains 2 sections:

- text/cloud-config
- text/cloud-boothook

### Section 1 - text/cloud-config

Contains the global parameters like uuid, token, org-name, vbond, root-ca cert - properties encoded in the part in YAML format and others:
- vinitparam:
  - uuid
  - vbond
  - otp
  - org
  - rcc
- ca-certs
- format-partition (vManage only)

The following example illustrates a cloud-config section:

```yaml
#cloud-config
vinitparam:
 - uuid : C8K-XXXXXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 - otp : 01009d55e49240e285f3a9e3176415a7
 - org : ciscotme-cloud-fabric
 - vbond: 192.168.3.1
```

`uuid` - is the UUID for the Catalyst 8000v. You get that from SD-WAN Manager device list.

`otp` is the one time password for c8000v. Again something you get from SD-WAN Manager device list. Giving the chassis number as uuid and serial number as otp, C8000v boots up with those information already configured.

`org` is the org-name configured on your SD-WAN Manager

`vbond` is it’s SD-WAN Validator (vbond) address, and org is Organization Name. When these are in cloud-config, C8000v is initialized with those information.

### Section 2 - text/cloud-boothook

Contains the actual SD-WAN configuration of the device. The following example illustrates a cloud-boothook section:

```example
#cloud-boothook
  system
   personality           vedge
   device-model          vedge-C8000V
   chassis-number        C8K-XXXXXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   system-ip             192.168.101.1
   site-id               1001
   sp-organization-name  "ciscotme-cloud-fabric"
   organization-name     "ciscotme-cloud-fabric"
   config-template-name  Default_Azure_vWAN_C8000V_Template_V01
   vbond 192.168.3.1 port 12346
  !
  !
  bfd default-dscp 48
  bfd app-route multiplier 2
  bfd app-route poll-interval 123400
  !
  !
  sdwan
   interface GigabitEthernet1
    tunnel-interface
     encapsulation ipsec weight 1
     color default
     no allow-service all
     no allow-service bgp
     allow-service dhcp
     allow-service dns
     allow-service icmp
     allow-service sshd
     no allow-service netconf
     no allow-service ntp
     no allow-service ospf
     no allow-service stun
     allow-service https
     no allow-service snmp
     no allow-service bfd
    exit
   exit
   interface GigabitEthernet2
   exit
   !
   !
   omp
    no shutdown
    send-path-limit  4
    ecmp-limit       4
    graceful-restart
    no as-dot-notation
    timers
     holdtime               15
     advertisement-interval 1
     graceful-restart-timer 120
     eor-timer              300
    exit
    address-family ipv4
     advertise connected
     advertise static
    !
    address-family ipv6
     advertise connected
     advertise static
    !
   !
  !
  hostname sdwanlab-edge-1
  !
  username admin privilege 15 secret 0 <PASSWORD>
  !
  vrf definition Mgmt-intf
   rd 1:512
   address-family ipv4
    route-target export 1:512
    route-target import 1:512
    exit-address-family
   !
   address-family ipv6
    exit-address-family
   !
  !
  interface GigabitEthernet1
   no shutdown
   ip address dhcp client-id GigabitEthernet1
   ip dhcp client default-router distance 1
   ip mtu    1500
   load-interval 30
   mtu           1500
   negotiation auto
  exit
  interface GigabitEthernet2
   no shutdown
   ip address dhcp client-id GigabitEthernet2
   ip dhcp client default-router distance 1
   ip mtu    1500
   load-interval 30
   mtu           1500
   negotiation auto
  exit
  interface Tunnel1
   no shutdown
   ip unnumbered GigabitEthernet1
   no ip redirects
   ipv6 unnumbered GigabitEthernet1
   no ipv6 redirects
   tunnel source GigabitEthernet1
   tunnel mode sdwan
  exit
  clock timezone UTC 0 0
  aaa authentication login default local
  aaa authorization exec default local
  aaa server radius dynamic-author
  !
  line con 0
   speed    19200
   stopbits 1
  !
  line vty 0 4
   transport input ssh
  !
  line vty 5 80
   transport input ssh
  !
 !
!
```

## 2. Creating Bootstrap file using Cisco Ansible SD-WAN collection

Cisco provides a new set of Ansible Collections to help deploying and configuring SD-WAN and SD-Routing devices.

[SD-WAN Ansible Collection examples](https://github.com/cisco-open/ansible-collection-sdwan)

- Which uses to sub repos:
  - [SD-WAN Ansible collection to deploy on aws (controllers+c8kv)](https://github.com/cisco-open/ansible-collection-sdwan-deployment)
  - [SD-WAN Ansible collection for various tasks](https://github.com/cisco-open/ansible-collection-catalystwan)

[SD-WAN Ansible collection to deploy on aws (controllers+c8kv)](https://github.com/cisco-open/ansible-collection-sdwan-deployment) includes a role to [generate and get a bootstrap config](https://github.com/cisco-open/ansible-collection-sdwan-deployment/tree/main/roles/template_cloudinit) 

Simply create an ansible playbook with the appropriate parameters and you get a bootstrap file that you can use to instantiate a C8000v.

## 3. Creating Bootstrap File from SD-WAN Manager

Get a bootstrap file generated by SD-WAN Manager as a reference and change as required.

Create a basic Configuration Group or Device Template and attach that template to your device. Enter all parameters and deploy.

Then go to Configuration > Device > WAN Edge List

Click on the 3-dots on the right of a device and pick "Generate bootstrap configuration"

SD-WAN Manager (vManage) will generate a cloud-init file that contains the cloud-config and cloud-boothook parts. This file is MIME encoded 

Select Cloud-Init. Then click OK.

Download the file. That gives you the bootstrap config that you can apply when you instantiate the Catalyst 8000v.

Once downloaded, you can then tune this file according to your needs.

> Note: this file can be used to load a C8000v (ciscosdwan_cloud_init.cfg file) or for hardware router (ciscosdwan.cfg). This file can be copied to the flash and used at bootup when you reset from factory. This is just FYI, because this is not used for Cloud deployment.

## 4. Creating Bootstrap file using Linux tools

Not the preferred option because cloud-init format can change in the future. But it highlights the fact that the bootstrap file is a very generic mime-encoded file that you can easily tune to your need.

You can utilize `write-mime-multipart` application. It’s included in the `cloud-utils` package, so installation can be done in this way:

- Ubuntu or Debian: `apt-get install cloud-utils`
- Redhat or CentOS: `yum install cloud-utils`

You have to build 2 files:

- cloud-config => cloud-config.txt
- cloud-boothook => cloud-boothook.txt

When you have each data in text files, you can combine them and construct a multipart text:

```shell
write-mime-multipart --output=ciscosdwan_cloud_init.cfg cloud-config.txt:text/cloud-config cloud-boothook.txt:text/cloud-boothook
```



