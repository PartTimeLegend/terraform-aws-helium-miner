data "aws_ami" "al2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "miner" {
  instance_type        = var.instance_type
  ami                  = data.aws_ami.al2.id
  iam_instance_profile = aws_iam_instance_profile.profile



  tags = {
    Name = "Helium-Miner"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.miner.id
  allocation_id = aws_eip.eip.id
}

resource "aws_eip" "eip" {
  vpc = true
}
