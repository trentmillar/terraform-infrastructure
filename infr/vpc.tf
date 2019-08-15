provider "aws" {
  region = "${var.region}"
  //profile = "${var.aws_profile}"
}

terraform {
    backend "s3" { }
}

locals {
    kubernetes_prv_subnet_tags = "${map(
        "${var.kubernetes_cluster_key}",
        "${var.kubernetes_cluster_value}",
        "${var.kubernetes_elb_internal_key}",
        "${var.kubernetes_elb_internal_value}"
    )}"
    kubernetes_pub_subnet_tags = "${map(
        "${var.kubernetes_cluster_key}",
        "${var.kubernetes_cluster_value}",
        "${var.kubernetes_elb_key}",
        "${var.kubernetes_elb_value}"
    )}"
}

// Define our single VPC for our subnets
resource "aws_vpc" "cluster_vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true
  tags = {
      Name = "VPC-Kube"
  }
}

// Begin - Public Subnets
resource "aws_subnet" "public_subnet_1" {
  cidr_block        = "${var.public_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Public-Subnet-1"
    "${var.kubernetes_cluster_key}" = "${var.kubernetes_cluster_value}"
    "${var.kubernetes_elb_key}" = "${var.kubernetes_elb_value}"
  }
  /* tags = "${merge(
      local.kubernetes_prv_subnet_tags,
      map(
          Name, "public_subnet_1"
      )
  )}" */
}

resource "aws_subnet" "public_subnet_2" {
  cidr_block        = "${var.public_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2b"
  tags = {
      Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  cidr_block        = "${var.public_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2c"
  tags = {
      Name = "Public-Subnet-3"
  }
}
// End - Public Subnets

// Begin - Private Subnets
resource "aws_subnet" "private_subnet_1" {
  cidr_block        = "${var.private_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Private-Subnet-1"
  }
  /* tags = "${merge(
      local.kubernetes_prv_subnet_tags,
      map(
          Name, "private_subnet_1"
      )
  )}" */
}

resource "aws_subnet" "private_subnet_2" {
  cidr_block        = "${var.private_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2b"
  tags = {
      Name = "Private-Subnet-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  cidr_block        = "${var.private_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "us-west-2c"
  tags = {
      Name = "Private-Subnet-3"
  }
}
// End - Private Subnets

// Begin - Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags = {
      Name = "Public-Route-Table"
  }
}
// End - Public Route Table

// Begin - Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags = {
      Name = "Private-Route-Table"
  }
}
// End - Private Route Table

// Begin - Public Route Table Associations
resource "aws_route_table_association" "public_route_table-1-association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public_subnet_1.id}"
}

resource "aws_route_table_association" "public_route_table-2-association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public_subnet_2.id}"
}

resource "aws_route_table_association" "public_route_table-3-association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public_subnet_3.id}"
}
// End - Public Route Table Associations

// Begin - Private Route Table Associations
resource "aws_route_table_association" "private_route_table-1-association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private_subnet_1.id}"
}

resource "aws_route_table_association" "private_route_table-2-association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private_subnet_2.id}"
}

resource "aws_route_table_association" "private_route_table-3-association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private_subnet_3.id}"
}
// End - Private Route Table Associations

// Begin - Assign Elastic IPs
resource "aws_eip" "elastic_ip_for_nat_gw" {
  vpc                       = true
  associate_with_private_ip = "192.168.0.5"
  tags = {
      Name = "Testing-EIP"
  }
}
// End - Assign Elastic IPs

// Begin - Create NAT GW
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.elastic_ip_for_nat_gw.id}"
  subnet_id     = "${aws_subnet.public_subnet_1.id}"
  tags = {
      Name = "Tesing-NAT-DW"
  }

  depends_on    = ["aws_eip.elastic_ip_for_nat_gw"]
}
// End - Create NAT GW

// Begin - Associate Private Route Table to NAT GW

// 0.0.0.0/0 allows our server to access external ips
resource "aws_route" "nat_gw_route" {
  route_table_id            = "${aws_route_table.private_route_table.id}"
  nat_gateway_id            = "${aws_nat_gateway.nat_gw.id}"
  destination_cidr_block    = "0.0.0.0/0"
}
// End - Associate Private Route Table to NAT GW

// Begin - Create Internet GW
resource "aws_internet_gateway" "testing_igw" {
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    tags = {
        Name = "Testing-IGW"
    }
}
// End - Create Internet GW

// Begin - Associate Public Route Table to Internet GW
resource "aws_route" "public_internet_gw_route" {
  route_table_id            = "${aws_route_table.public_route_table.id}"
  gateway_id                = "${aws_internet_gateway.testing_igw.id}"
  destination_cidr_block    = "0.0.0.0/0"
}
// End - Associate Public Route Table to Internet GW