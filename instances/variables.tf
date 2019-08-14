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

variable "max_instance_size" {
  description = "Max instances to launch"
}

variable "min_instance_size" {
  description = "Min instances to launch"
}

variable "autoscaling_sns_sms_endpoint" {
  description = "Number to send message to"
}

variable "general_ami_id" {
  description = "Ubuntu 18.04 LTS"
  default = "ami-05c1fa8df71875112"
}