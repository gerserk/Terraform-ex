terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# AMI for most recent ubuntu
data "aws_ami" "ubuntu"{
  most_recent = true
  filter {
    # filter with name who matches this pattern
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  # filter for hvm virtualization 
  filter {
    name   = "virtualization-type"
    values = ["hvm"] # hw virtual mach
  }

  # Canonical
  owners = ["099720109477"]
}

resource "aws_vpc" "main"{
  cidr_block = var.cidr_block
  instance_tenancy = "default"
}

resource "aws_subnet" "public"{
  vpc_id = aws_vpc.main.id
  count = length(var.availability_zones)
  availability_zone  = element(var.availability_zones, count.index)
  # cidr base, new bits /16->/24, step .1.0:.2.0... 
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public subnet: ${element(var.availability_zones, count.index)}"
    Type = "Public"
  }
}

resource "aws_subnet" "private"{
  vpc_id = aws_vpc.main.id
  count = length(var.availability_zones)
  availability_zone = element(var.availability_zones, count.index)
  # count + leng per non avere overlapping di IP 
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
    # assign nat to first subnet
    subnet_id = aws_subnet.public[0].id
    allocation_id = aws_eip.nat.id

    depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_launch_template" "webtemplate" {
    image_id = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = aws_security_group.webserver

    user_data = filebase64("./ec2.userdata")
    tags = {
        Name = "WebServer"
    }
}

resource "aws_lb" "alb" {
    internal = false
    load_balancer_type = "application"
    security_groups = aws_security_group.alb.id
    subnets = aws_subnet.public.*.id
    enable_deletion_protection = false

  /*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
  */
}
# target dove route traffic
resource "aws_alb_target_group" "webserver" {
    vpc_id = aws_vpc.main.id
    port = 80
    protocol = "HTTP"
}
# checks incoming traffic
resource "aws_alb_listener" "frontend" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_alb_target_group.webserver.arn
    }
}

resource "aws_alb_listener_rule" "alb_rule1" {
    listener_arn = aws_alb_listener.frontend.arn
    priority = 99

    action {
        type = "forward"
        target_group_arn = aws_alb_target_group.webserver.arn
    }

    condition {
        path_pattern {
            values = ["/"]
        }
    }
}

resource "aws_autoscaling_group" "ag1" {
    vpc_zone_identifier = aws_subnet.private.*.id
    desired_capacity = 2
    min_size = 2
    max_size = 3

    target_group_arns = [aws_alb_target_group.webserver.arn]
    launch_template {
        id = aws_launch_template.webtemplate.id
        version = "$Latest"
    }

    depends_on = [
    aws_nat_gateway.nat
  ]
}

# data "aws_instance" "webserver" {
#     instance_tags {
#         Name = "WebServer"
#     }

#     epends_on = [
#     aws_autoscaling_group.asg
#   ]
# }

