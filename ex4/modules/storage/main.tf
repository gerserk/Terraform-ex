terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_instance" "mongo" {
  ami                    = "ami-02868af3c3df4b3aa"
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = false
  
  root_block_device {
    volume_size = 10
    encrypted   = true
  }
  
  # instal and populate mongo a bit
  user_data = filebase64("./modules/storage/install.sh")
}