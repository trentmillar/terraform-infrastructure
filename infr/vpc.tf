provider "aws" {
  region = "${var.region}"
}

terraform {
    backend "s3" { }
}

// Define our single VPC for our subnets
resource "aws_vpc" "testing-vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
      Name = "Test-VPC"
  }
}

// Begin - define subnets
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = "${var.public_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2a"

  tags {
      Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block        = "${var.public_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2b"

  tags {
      Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "public-subnet-3" {
  cidr_block        = "${var.public_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2c"

  tags {
      Name = "Public-Subnet-3"
  }
}
// End - define subnets
