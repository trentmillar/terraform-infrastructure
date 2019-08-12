provider "aws" {
  region = "${var.region}"
}

terraform {
    backend "s3" { }
}

resource "aws_vpc" "testing-vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true

  tags {
      Name = "Test-VPC"
  }
}
