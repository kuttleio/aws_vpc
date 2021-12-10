variable "tags" {
  description = "tags to propogate to all supported resources"
  type        = map
}

variable "az_count" {
  description = "the number of AZs to deploy infrastructure to"
  default     = 3
}

variable "vpc_name" {
  description = "name of the VPC to create"
}

variable "vpc_cidr" {
  description = "CIDR associated with the VPC to be created"
}

variable "private_subnet_size" {
  default = 24
}

variable "public_subnet_size" {
  default = 26
}

variable "enable_public_subnets" {
  type    = string
  default = "true"
}

variable "enable_private_subnets" {
  type    = string
  default = "true"
}

variable "enable_vpn_gateway" {
  type    = string
  default = "true"
}

variable "enable_internet_gateway" {
  type    = string
  default = "true"
}

variable "enable_nat_gateway" {
  type        = string
  description = "NAT gateway requires Internet GW to operate, so if enable_nat_gateway is true, enable_internet_gateway should be true as well"
  default     = "true"
}

variable "ha_nat_gateway" {
  description = "Optional Highly available NAT gateways (1 per AZ) set to false for cheaper testing. Applicable only if enable_nat_gateway is true"
  default     = "true"
}

variable "vpn_gateway_amazon_asn" {
  description = "ASN for Amazon side"
  type        = number
  default     = 64512
}
