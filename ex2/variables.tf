variable "access_key" {
  type = string
}
variable "secret_key" {
  type = string
}
variable "region" {
  type = string
}
variable "cidr_vpc" {
  type = string
}
variable "cidr_subnet_public_a" {
  type = string
}
variable "cidr_subnet_public_b" {
  type = string
}
variable "cidr_subnet_private_a" {
  type = string
}
variable "cidr_subnet_private_b" {
  type = string
}
variable "key_name" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "webserver_sg_rules" {
  type = object({
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  })
  default = {
    ingress_rules = [
      {
        description = "SSH from management workstation"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["1.1.1.1/32"] # metti workstation IP
      },
      {
        description = "80 from public subnets" # alb associato con loro
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
      },
    ]
    egress_rules = [
      {
        description = "All outbound internet traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}