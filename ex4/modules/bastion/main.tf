terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_instance" "bastion" {
    subnet_id = var.subnet_id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [var.sg_id]
    associate_public_ip_address = true
    ami = "ami-02868af3c3df4b3aa"

    # requested
    root_block_device {
        volume_size = 10
        encrypted   = true
  }

}