# rt for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public"
  }
}

resource "aws_route" "public_igw" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "rta_public" {
  count = length(var.availability_zones)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# rt for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  count = length(var.availability_zones)

  tags = {
    "Name" = "Private: ${element(var.availability_zones, count.index)}"
  }
}

resource "aws_route" "private_nat" {
  nat_gateway_id = aws_nat_gateway.nat.id
  destination_cidr_block = "0.0.0.0/0"
  count = length(var.availability_zones)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "rta_private" {
  count = length(var.availability_zones)
  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id = element(aws_subnet.private.*.id, count.index)
}

