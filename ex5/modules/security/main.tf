terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_security_group" "webserver" {
    name = "webserver"
    description = "sg for the 2 nginx instances"
    vpc_id = var.vpc_id
    # could do dynamically, not needed in this case
    ingress {
        description = "ingress 80 from alb"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = var.public_subnets_ids
    }

    ingress {
        description = "ingress 8080 from alb"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = var.public_subnets_ids
    }

    # could maybe put bastion as main ansible node
    ingress {
        description     = "22 from bastion"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.bastion.id]
    }

    egress {
        description = "outbound traffic to all"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "bastion" {
    name = "bastion"
    vpc_id = var.vpc_id

    ingress {
    description = "22 from workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # just for testing! this exposes it to the world!
    # should put my workstation ip
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_security_group" "alb" {
    name = "alb"
    vpc_id = var.vpc_id

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    description     = "all all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    # outbound traffic only to this sg
    security_groups = [aws_security_group.webserver.id]
  }

}

resource "aws_security_group" "mongodb" {
    name = "mongodb"
    
    ingress {
        description = "27017 from webserver"
        from_port   = 27017
        to_port     = 27017
        protocol    = "tcp"
        # instead of putting cidr_blocks
        security_groups = [aws_security_group.webserver.id]
  }

    ingress {
        description     = "22 from bastion"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [aws_security_group.bastion.id]
  }

    egress {
        description = "all all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] 
    }


}