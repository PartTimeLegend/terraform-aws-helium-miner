resource "aws_security_group" "group" {
  name   = "helium-miner-security-group"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port        = 1680
    to_port          = 1680
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 44158
    to_port          = 44158
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
