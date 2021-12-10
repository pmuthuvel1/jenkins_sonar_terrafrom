variable "region-name" {
  default = "us-east-2"
  type    = string
}

variable "env" {
  default = "staging"
  type    = string
}

variable "cidr-block-admin" {
  default = "10.0.0.0/16"
  type    = string
}

variable "cidr-routetable-admin" {
  default = "10.0.0.0/24"
  type    = string
}

variable subnet_wp_admin {
   default = "subnet_wp_admin"
   type    = string
}

variable "cidr-block-subnet-admin" {
  default = "12.1.2.0/16"
  type    = string
}


#RDS Varialbles


variable "engine" {
  default = "12.1.2.0/16"
  type    = string
}
variable "engine_version" {
  default = "12.1.2.0/16"
  type    = string
}     
variable "instance_class" {
  default = "12.1.2.0/16"
  type    = string
}
variable "name"  {
  default = "12.1.2.0/16"
  type    = string
}       
variable "username" {
  default = "12.1.2.0/16"
  type    = string
}  
variable "password" {
  default = "12.1.2.0/16"
  type    = string
} 
variable "parameter_group_name" {
  default = "12.1.2.0/16"
  type    = string
}