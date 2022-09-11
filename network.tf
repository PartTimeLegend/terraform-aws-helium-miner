resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "helium-miner-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = var.availability_zone
}

resource "aws_network_interface" "ni" {
  subnet_id   = aws_subnet.subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}
