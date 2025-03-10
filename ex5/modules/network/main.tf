
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_vpc" "main"{
  cidr_block = var.cidr_block
  instance_tenancy = "default"
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    count = length(var.availability_zones)
    availability_zone = element(var.availability_zones, count.index)
    cidr_block = cidrsubnet(var.cidr_block, 8, count.index)
    map_public_ip_on_launch = true

    tags = {
        Name = "Public subnet: ${element(var.availability_zones, count.index)}"
        Type = "Public"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    count = length(var.availability_zones)
    availability_zone = element(var.availability_zones, count.index)
    cidr_block = cidrsubnet(var.cidr_block, 8, count.index + length(var.availability_zones))
    map_public_ip_on_launch = false

    tags = {
    Name = "Private Subnet: ${element(var.availability_zones, count.index)}"
    Type = "Private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count = length(var.availability_zones)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  allocation_id = aws_eip.nat.id

  depends_on = [
    aws_internet_gateway.igw
  ]
}


