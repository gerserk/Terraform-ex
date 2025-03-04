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
  cidr_block = var.cidr_vpc
}

resource "aws_subnet" "public_a"{
  vpc_id = aws_vpc.main.id
  availability_zone  = "eu-west-1a"
  cidr_block = var.cidr_subnet_public_a
  map_public_ip_on_launch = true
  tags = {
    Type = "Public"
  }
}

resource "aws_subnet" "private_a"{
  vpc_id = aws_vpc.main.id
  availability_zone  = "eu-west-1a"
  cidr_block = var.cidr_subnet_private_a
  tags = {
    Type = "Public"
  }
}

resource "aws_subnet" "public_b"{
  vpc_id = aws_vpc.main.id
  availability_zone  = "eu-west-1b"
  cidr_block = var.cidr_subnet_public_b
  map_public_ip_on_launch = true # if public ip should be assigned to instance  
  tags = {
    Type = "Public"
  }
}

resource "aws_subnet" "private_b"{
  vpc_id = aws_vpc.main.id
  availability_zone  = "eu-west-1b"
  cidr_block = var.cidr_subnet_private_b
  tags = {
    Type = "Public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw1"
  }
} 

resource "aws_route" "igw_route" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# elastic ip
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat
  subnet_id = aws_subnet.public_a.id

  # best practice
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_launch_template" "launchtemplate1" {
  name = "webserver0"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.webserver.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "WebServer"
    }
  }
  user_data = filebase64("./ec2.userdata")
}

resource "aws_lb" "alb1" {
  name = "alb1"
  internal = false # true per interno (IP privati)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false
# logs in s3 volendo
  /*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
  */

  tags = {
    Environment = "Prod"
  }
}

resource "aws_alb_target_group" "webserver" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# checks incoming traffic for protocol / port e forward (handles incoming req)
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }
}

resource "aws_alb_listener_rule" "rule1" {
  listener_arn = aws_alb_listener.front_end.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webserver.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  target_group_arns = [aws_alb_target_group.webserver.arn]

  launch_template {
    id      = aws_launch_template.launchtemplate1.id
    version = "$Latest"
  }
}



