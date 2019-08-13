variable "region" {
  default = "us-west-2"
}

variable "remote_state_bucket" {
  description = "Bucket with state"
}

variable "remote_state_key" {
  description = "Key for state"
}

variable "ec2_instance_type" {
  description = "EC2 instance type to launch"
}

variable "keypair_name" {
  description = "AWS Key pair used to connect to EC2 instances"
  default = "scheduler"
}

