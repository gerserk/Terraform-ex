variable "mongodb_ip" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "webserver_sg_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}
