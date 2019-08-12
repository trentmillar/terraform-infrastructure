provider "aws" {
  region    = "${var.region}"
}

terraform {
    backend "s3" { }
}

// Define our single VPC for our subnets
resource "aws_vpc" "testing-vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true

  tags {
      Name  = "Test-VPC"
  }
}

// Begin - Public Subnets
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = "${var.public_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2a"

  tags {
      Name  = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block        = "${var.public_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2b"

  tags {
      Name  = "Public-Subnet-2"
  }
}

resource "aws_subnet" "public-subnet-3" {
  cidr_block        = "${var.public_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2c"

  tags {
      Name  = "Public-Subnet-3"
  }
}
// End - Public Subnets

// Begin - Private Subnets
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = "${var.private_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2a"

  tags {
      Name  = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  cidr_block        = "${var.private_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2b"

  tags {
      Name  = "Private-Subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  cidr_block        = "${var.private_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.testing-vpc.id}"
  availability_zone = "us-west-2c"

  tags {
      Name  = "Private-Subnet-3"
  }
}
// End - Private Subnets

// Begin - Public Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id    = "${aws_vpc.testing-vpc.id}"

  tags {
      Name  = "Public-Route-Table"
  }
}
// End - Public Route Table

// Begin - Private Route Table
resource "aws_route_table" "private-route-table" {
  vpc_id    = "${aws_vpc.testing-vpc.id}"

  tags {
      Name  = "Private-Route-Table"
  }
}
// End - Private Route Table

// Begin - Public Route Table Associations
resource "aws_route_table_association" "public-route-table-1-association" {
  route_table_id    = "${aws_route_table.public-route-table.id}"
  subnet_id         = "${aws_subnet.public-subnet-1.id}"
}

resource "aws_route_table_association" "public-route-table-2-association" {
  route_table_id    = "${aws_route_table.public-route-table.id}"
  subnet_id         = "${aws_subnet.public-subnet-2.id}"
}

resource "aws_route_table_association" "public-route-table-3-association" {
  route_table_id    = "${aws_route_table.public-route-table.id}"
  subnet_id         = "${aws_subnet.public-subnet-3.id}"
}
// End - Public Route Table Associations

// Begin - Private Route Table Associations
resource "aws_route_table_association" "private-route-table-1-association" {
  route_table_id    = "${aws_route_table.private-route-table.id}"
  subnet_id         = "${aws_subnet.private-subnet-1.id}"
}

resource "aws_route_table_association" "private-route-table-2-association" {
  route_table_id    = "${aws_route_table.private-route-table.id}"
  subnet_id         = "${aws_subnet.private-subnet-2.id}"
}

resource "aws_route_table_association" "private-route-table-3-association" {
  route_table_id    = "${aws_route_table.private-route-table.id}"
  subnet_id         = "${aws_subnet.private-subnet-3.id}"
}
// End - Private Route Table Associations