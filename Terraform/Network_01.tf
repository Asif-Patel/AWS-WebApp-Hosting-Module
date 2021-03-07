provider "aws" {
    region = "eu-west-1"
    shared_credentials_file = "XXXXX/.aws/credentials"
    profile = "XXXXX"
}

#VPC Creation
resource "aws_vpc" "vpc-webapp" {
    cidr_block = "172.0.0.0/24"
    instance_tenancy = "default"
    tags = {
      "Name" = "vpc-webapp"
    }
}

#Public Subnets
resource "aws_subnet" "pub-subnet-1" {
  vpc_id     = aws_vpc.vpc-webapp.id
  cidr_block = "172.0.0.64/26"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_subnet" "pub-subnet-2" {
  vpc_id     = aws_vpc.vpc-webapp.id
  cidr_block = "172.0.0.128/26"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "public-subnet-1b"
  }
}

#Private Subnets
resource "aws_subnet" "pri-subnet-1" {
  vpc_id     = aws_vpc.vpc-webapp.id
  cidr_block = "172.0.0.192/27"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "private-subnet-1a"
  }
}

resource "aws_subnet" "pri-subnet-2" {
  vpc_id     = aws_vpc.vpc-webapp.id
  cidr_block = "172.0.0.224/27"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "int-gw" {
  vpc_id = aws_vpc.vpc-webapp.id
  tags = {
    Name = "int-gw"
  }
}

#Elastic IP
resource "aws_eip" "eip" {
  vpc = true
  tags = {
    "Name" = "eip-1"
  }
}

#NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub-subnet-1.id
  tags = {
      Name = "nat-gw-1a"
  }
}

/*resource "aws_nat_gateway" "nat-gw-1b" {
  allocation_id = aws_eip.nat-1b.id
  subnet_id     = aws_subnet.pub-subnet-2.id
  tags = {
      Name = "nat-gw-1b"
  }
}*/

#Route Tables
resource "aws_route_table" "route-table-1" {
  vpc_id = aws_vpc.vpc-webapp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int-gw.id
  }
  tags = {
    Name = "pub-route-table"
  }
}

resource "aws_route_table" "route-table-2" {
  vpc_id = aws_vpc.vpc-webapp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "pri-route-table"
  }
}

#Route Table Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub-subnet-1.id
  route_table_id = aws_route_table.route-table-1.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pub-subnet-2.id
  route_table_id = aws_route_table.route-table-1.id
}
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.pri-subnet-1.id
  route_table_id = aws_route_table.route-table-2.id
}
resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.pri-subnet-2.id
  route_table_id = aws_route_table.route-table-2.id
}