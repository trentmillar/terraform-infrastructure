provider "aws" {
  region = "${var.region}"
}

terraform {
    backend "s3" { }
}

resource "aws_vpc" "scheduling-vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true

  tags {
      Name = "Scheduling-VPC"
  }
}
