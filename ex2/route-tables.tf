# rt for public subnets
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public"
  }
}
# rt for private subnets
resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private"
  }
}
# for the 2 public subnets
resource "aws_route_table_association" "rta1" {
    route_table_id = aws_route_table.rt1.id
    subnet_id = aws_subnet.public_a.id
}

resource "aws_route_table_association" "rta2" {
    route_table_id = aws_route_table.rt1.id
    subnet_id = aws_subnet.public_b.id
}
# for the 2 private subnets
resource "aws_route_table_association" "rta3" {
    route_table_id = aws_route_table.rt2.id
    subnet_id = aws_subnet.private_a.id
}
resource "aws_route_table_association" "rta4" {
    route_table_id = aws_route_table.rt2.id
    subnet_id = aws_subnet.private_b.id
}