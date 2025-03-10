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

module "network" {
  source = "./modules/network"

  availability_zones = var.availability_zones
  cidr_block         = var.cidr_block
}

module "security" {
  source = "./modules/security"

  vpc_id         = module.network.vpc_id
  public_subnets_ids = module.network.public_subnets_ids
  private_subnets_ids = module.network.private_subnets_ids

  depends_on = [
    module.network
  ]
}

module "bastion" {
  source = "./modules/bastion"

  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = module.network.public_subnets_ids[0]
  sg_id         = module.security.bastion_sg_id

  depends_on = [
    module.network,
    module.security
  ]
}

module "storage" {
  source = "./modules/storage"

  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = module.network.private_subnets_ids[0]
  sg_id         = module.security.mongodb_sg_id

  depends_on = [
    module.network,
    module.security
  ]
}

module "application" {
  source = "./modules/application"

  instance_type   = var.instance_type
  key_name        = var.key_name
  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets_ids
  private_subnets = module.network.private_subnets_ids
  webserver_sg_id = module.security.webserver_sg_id
  alb_sg_id       = module.security.alb_sg_id
  mongodb_ip      = module.storage.private_ip

  depends_on = [
    module.network,
    module.security,
    module.storage
  ]
}
