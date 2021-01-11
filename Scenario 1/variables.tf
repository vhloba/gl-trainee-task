variable "profile" {
  default = "default"
}

variable "region" {
  default = "eu-central-1"
}

variable "vpc_cidr_block" {
  default = "10.10.0.0/16"
}

variable "subnet_a_cidr_block" {
  default = "10.10.101.0/24"
}

variable "subnet_b_cidr_block" {
  default = "10.10.102.0/24"
}

variable "subnet_a_az" {
  default = "eu-central-1a"
}

variable "subnet_b_az" {
  default = "eu-central-1b"
}

variable "map_public_ip" {
  type    = bool
  default = true
}

variable "ami" {
  default = "ami-01b65a06ec09db85c" # Microsoft Windows Server 2019 Base
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "The key name of the Key Pair to use for the instance"
}


