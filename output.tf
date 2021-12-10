output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "public_subnets_arns" {
  value = aws_subnet.public_subnets.*.arn
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}

output "private_subnets_arns" {
  value = aws_subnet.private_subnets.*.arn
}

output "vpn_gateway_id" {
  value = var.enable_vpn_gateway == "true" ? aws_vpn_gateway.vpn_gw[0].id : null
}

output "igw_id" {
  value = var.enable_internet_gateway == "true" ? module.aws_internet_gateway.igw_id : null
}

output "public_routes" {
  value = aws_route_table.public_route.*.id
}

output "private_routes" {
  value = aws_route_table.private_route.*.id
}

output "nat_gateway_ids" {
  value = var.enable_nat_gateway == "true" ? aws_nat_gateway.ngw.*.id : null
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

output "default_security_group_id" {
  value = aws_vpc.vpc.default_security_group_id
}
