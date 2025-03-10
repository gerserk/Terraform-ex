variable access_key {
  type        = string
}
variable secret_key {
    type = string
}
variable region {
    type = string
}
variable availability_zones {
    type = list(string)
}
variable "cidr_block" {
  type = string
}
variable instance_type {
    type = string
}
variable key_name {
    type = string
}