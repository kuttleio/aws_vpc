# aws_vpc

This module can create:<br>
VPC, Internet Gateway, Private Subnets, Public Subnets, Route Tables, NAT Gateway, VPC Endpoint for S3<br>


If you create 2xPrivate Subnets and 2xPublic Subnets with IGW and NAT `enabled`, Subnet will have names:
```
xyz-private-1
xyz-private-2
xyz-public-1
xyz-public-2
```

If you create 2xPrivate Subnets and 2xPublic Subnets with IGW and NAT `disabled`, Subnet will have names:
```
xyz-private-1
xyz-private-2
xyz-private-3
xyz-private-4
```
Where `xyz` is VPC name.

# Inputs

| Name            | Description                                                                                 | Type   | Default | Required |
|------           |-------------                                                                                |:------:|:-------:|:-----:|
| vpc\_name       | Name of VPC (prod/dev/staging)                                                              | string | n/a  | yes |
| vpc\_cidr               | CIDR Block associated with the VPC to be created                                            | string | n/a  | yes |
| az\_count               | The number of AZs to use for creation of Subnets                                            | number | 3    | yes |
| ha\_nat\_gateway        | If true NATGateway will be created in each PublicSubnet, if false, only in one PublicSubnet | bool   | true | yes |
| enable\_public\_subnets | If true Public Subnet will be created                                                       | string | true | yes |
| enable\_private\_subnets | If true Public Subnet will be created                                                      | string | true | yes |
| public\_subnet\_size     | CIDR Notation to set size of Public Subnets                                            | number | 26   | yes |
| private\_subnet\_size    | CIDR Notation to set size of Private Subnets                                           | number | 24   | yes |
| enable\_vpn\_gateway     | Create VPN Gateway in VPC                                                              | string | true | yes |
| tags                     | Map of Tags to propogate to all supported resources                                     | map  | n/a | no |



## Outputs

| Name                     | Description |
|--------------------------|-------------|
| vpc\_id                   | VPC id         |
| vpc\_cidr                 | VPC CIDR Block |
| public\_subnets           | List of Public Subnet Ids |
| private\_subnets          | List of Private Subnet Ids |
| vpn\_gateway\_id          | Id of VPN Gateway  |
| igw\_id                   | Id of Internet Gateway |
| public\_routes            | List of Public Route Table Ids |
| private\_routes           | List of Private Route Table Ids |
| nat\_gateway\_ids         | List of NAT Gateway Ids |



Example of use:
```
module "vpc" {
  source              = "../../../../../../aws_vpc"
  vpc_name            = "${var.vpc_name}"
  vpc_cidr            = "${var.vpc_ip_cidr}"
  tags                = "${var.tags}"
  az_count            = "${var.az_count}"
  ha_nat_gateway      = "${var.ha_nat_gateway}"
  private_subnet_size = "${var.private_subnet_size}"
  public_subnet_size  = "${var.public_subnet_size}"
}
```
