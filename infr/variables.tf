variable "region" {
  default     = "us-west-2"
  description = "Default AWS Region"
}

variable "vpc_cidr" {
  default     = "192.168.0.0/16"
  description = "VPC CIDR Block"
}

variable "public_subnet_1_cidr" {
  description = "Public Subnet 1 CIDR"
}

variable "public_subnet_2_cidr" {
  description = "Public Subnet 2 CIDR"
}

variable "public_subnet_3_cidr" {
  description = "Public Subnet 3 CIDR"
}

variable "private_subnet_1_cidr" {
  description = "Private Subnet 1 CIDR"
}

variable "private_subnet_2_cidr" {
  description = "Private Subnet 2 CIDR"
}

variable "private_subnet_3_cidr" {
  description = "Private Subnet 3 CIDR"
}

variable "kubernetes_cluster_key" {
    description = "Key used by kubernetes"
}

variable "kubernetes_cluster_value" {
    description = "Value used by kubernetes"
}

variable "kubernetes_elb_internal_key" {
    description = "Key used by kubernetes"
}

variable "kubernetes_elb_internal_value" {
    description = "Value used by kubernetes"
}

variable "kubernetes_elb_key" {
    description = "Key used by kubernetes"
}

variable "kubernetes_elb_value" {
    description = "Value used by kubernetes"
}
