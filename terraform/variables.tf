variable "vpc_cidr_block" {
    description = "vpc cidr block"
    default = "10.0.0.0/16"
  
}

variable "public_subnet_cidr" {
    description = "public_subnet_cidr"
    default = "10.0.1.0/24"
  
}

variable "private_subnet_cidr" {
    description = "public_subnet_cidr"
    default = "10.0.2.0/24"
  
}

variable "ami" {
    description = "ami value for the instance"
    type    = string
    default = "ami-007020fd9c84e18c7"
  
}

variable "instance_type"{
    description = "instance type"
    type    = string
    default = "t3.micro"
}