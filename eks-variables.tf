####################################### Variables ########################################################3

variable "private_key_path" {
  type    = string
  default = "./Neeharika_Terraform.pem"
}
variable "key_name" {
  type        = string
  description = "key name"
  default     = "Neeharika_Terraform"
}
variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Name of the region to create resource"
}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet_address_space" {
  default = "10.1.0.0/24"
}

variable "instance_count" {
  default = 2
}

variable "subnet_count" {
  default = 2
}

variable "eks_name" {
  default = "neeha-eks-cluster"
}



