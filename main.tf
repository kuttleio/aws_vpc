data "aws_region" "current" {}
data "aws_availability_zones" "available_az" {}

locals {
  public_cidr      = cidrsubnet(var.vpc_cidr, 1, 0)
  private_cidr     = cidrsubnet(var.vpc_cidr, 1, 1)
  private_bit_diff = "${var.private_subnet_size - element(split("/", local.private_cidr), 1)}"
  public_bit_diff  = "${var.public_subnet_size - element(split("/", local.public_cidr), 1)}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, tomap({ Name = var.vpc_name }))
}

module "aws_internet_gateway" {
  // TODO: This is a workaround to optionally create VPC without IGW.
  // Terraform 0.12 doesn't support 'count' or/and 'for_each' for modules.
  // Apparently support will be added in 0.13 — https://github.com/hashicorp/terraform/issues/17519
  module_enabled = var.enable_internet_gateway == "true" ? "true" : "false"
  source         = "git@github.com:zbs-nu/source-launchpad-modules.git//aws_igw"
  tags           = merge(var.tags, tomap({ Name = "${var.vpc_name}-igw" }))
  vpc_id         = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnets" {
  count             = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.public_cidr, local.public_bit_diff, count.index)
  availability_zone = data.aws_availability_zones.available_az.names[count.index]
  tags              = merge(var.tags, tomap({ Name = "${var.vpc_name}-${var.enable_internet_gateway == "true" ? "public-${count.index + 1}" : "private-${count.index + 1 + (var.az_count * (var.enable_private_subnets == "true" ? 1 : 0))}"}" }))
}

resource "aws_subnet" "private_subnets" {
  count             = var.az_count * (var.enable_private_subnets == "true" ? 1 : 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.private_cidr, local.private_bit_diff, count.index)
  availability_zone = data.aws_availability_zones.available_az.names[count.index]
  tags              = merge(var.tags, tomap({ Name = "${var.vpc_name}-private-${count.index + 1}" }))
}

resource "aws_route_table" "public_route" {
  count  = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, tomap({ Name = "${var.vpc_name}-${var.enable_internet_gateway == "true" ? "public-rt-${count.index + 1}" : "private-rt-${count.index + 1 + (var.az_count * (var.enable_private_subnets == "true" ? 1 : 0))}"}" }))
}

resource "aws_route" "public_igw" {
  count                  = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0) * (var.enable_internet_gateway == "true" ? 1 : 0)
  route_table_id         = element(aws_route_table.public_route.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.aws_internet_gateway.igw_id
}

resource "aws_route_table_association" "public_route_assoc" {
  count          = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route.*.id, count.index)
}

resource "aws_route_table" "private_route" {
  count  = var.az_count * (var.enable_private_subnets == "true" ? 1 : 0)
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, tomap({ Name = "${var.vpc_name}-private-rt-${count.index + 1}" }))
}

resource "aws_route_table_association" "private_route_assoc" {
  count          = var.az_count * (var.enable_private_subnets == "true" ? 1 : 0)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route.*.id, count.index)
}

module "aws_eip" {
  // TODO: This is a workaround to optionally create VPC without NGW.
  // Terraform 0.12 doesn't support 'count' or/and 'for_each' for modules.
  // Apparently support will be added in 0.13 — https://github.com/hashicorp/terraform/issues/17519
  module_enabled = (var.enable_nat_gateway == "true" ? "true" : "false")
  source         = "git@github.com:zbs-nu/source-launchpad-modules.git//aws_eip"
  eip_count      = (var.ha_nat_gateway == "true" ? var.az_count : 1) * (var.enable_public_subnets == "true" ? 1 : 0)
  tags           = merge(var.tags, tomap({ Name = "${var.vpc_name}-nat-eip" }))
}

resource "aws_nat_gateway" "ngw" {
  count         = (var.ha_nat_gateway == "true" ? var.az_count : 1) * (var.enable_public_subnets == "true" ? 1 : 0) * (var.enable_nat_gateway == "true" ? 1 : 0)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)
  allocation_id = element(module.aws_eip.eip_alloc_id, count.index)
  tags          = merge(var.tags, tomap({ Name = "${var.vpc_name}-nat-${count.index + 1}" }))
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.az_count * (var.enable_public_subnets == "true" ? 1 : 0) * (var.enable_nat_gateway == "true" ? 1 : 0)
  route_table_id         = element(aws_route_table.private_route.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  count        = var.enable_private_subnets == "true" ? 1 : 0
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags         = merge(var.tags, tomap({ Name = "${var.vpc_name}-endpoint-to-s3" }))
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint" {
  count           = var.az_count * (var.enable_private_subnets == "true" ? 1 : 0)
  route_table_id  = element(aws_route_table.private_route.*.id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint[0].id
}

resource "aws_vpn_gateway" "vpn_gw" {
  count           = var.enable_vpn_gateway == "true" ? 1 : 0
  vpc_id          = aws_vpc.vpc.id
  amazon_side_asn = var.vpn_gateway_amazon_asn
  tags            = merge(var.tags, tomap({ Name = "${var.vpc_name}-vgw" }))
}

resource "aws_vpn_gateway_attachment" "default" {
  count          = var.enable_vpn_gateway == "true" ? 1 : 0
  vpc_id         = aws_vpc.vpc.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count          = (var.enable_vpn_gateway == "true" ? 1 : 0) * var.az_count * (var.enable_public_subnets == "true" ? 1 : 0)
  route_table_id = element(aws_route_table.public_route.*.id, count.index)
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count          = (var.enable_vpn_gateway == "true" ? 1 : 0) * var.az_count * (var.enable_private_subnets == "true" ? 1 : 0)
  route_table_id = element(aws_route_table.private_route.*.id, count.index)
  vpn_gateway_id = aws_vpn_gateway.vpn_gw[0].id
}
