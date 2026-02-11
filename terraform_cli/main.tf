provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "main" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  cidr_block           = "10.0.0.0/16"
  tags = {
    Name = "Data-Center-CA"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-c"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-routes"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow ping"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all on 8443"
  }

  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all on 5986"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all on 5986"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-security-group"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "my_public_ssh_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbl1nB/o3sUVBtk32IAoYanB5EyhPTK2Vpt7FzK4o7R5NMLkU7vzIgg4i6V6CtgQDdNlSdlsP7jmTvrwjjEQGnT9iVTOi78j6obURHD4VRqDnvUecq1GucSUGu2Tbht6CHu1622rznYgL2vTr5W+NqHozbgl4WfhWlr98FmKLCSRjqQjd5d8RP41+KoQ3VHIpdKqaFwtPCxXaQNLFV356z9fb4D1Peywt8P60NyWfPYwSmKxJ3jTpMhssyH+v6/Z2bjt+z8lbnHdaACxmkPHknr4CldTgMH+wjLliJ8PsXiWLv7Ts4wEzzP49TAlTAom/QqCVprpsro1fdfNhJDQQnCJWT48uXYHDewlOPdn7oyz3ZAOGS+/Mgs0jRD5Qx8ajP24eEbYdkdZu7YmraBbZ3LNjZZFkjOgSviH/oRQUZtRHUqB5+brMjUFm6qpVO3ps/J3pSdDyWX840xOqyCqUw3DwF9/b5z/966rnDStEw+gLudy+T/K2kN5qHGC4HBnE= awx@aap.internal.ames.net"
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Ubuntu"
  }
}

resource "aws_instance" "f5" {
  ami                    = data.aws_ami.f5_21.id
  instance_type          = "m5.xlarge"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "F5"
  }
}

resource "aws_instance" "RHEL9_web_A" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "RHEL9_web_A"
  }
}

resource "aws_instance" "RHEL9_web_C" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_c.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "RHEL9_web_C"
  }
}

resource "aws_instance" "win25" {
  ami                    = data.aws_ami.win25.id
  instance_type          = "m5.xlarge"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"
  user_data              = file("scripts/win25_userdata")

  tags = {
    Name = "Active Directory"
  }
}

resource "aws_instance" "satellite" {
  # RHEL 10
  ami                    = data.aws_ami.rhel10.id
  instance_type          = "m5.2xlarge"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Satellite"
  }
}

resource "aws_instance" "panos" {
  ami                    = data.aws_ami.panos.id
  instance_type          = "c5n.xlarge"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Panos"
  }
}

resource "aws_instance" "idm" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_c.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Identity Management"
  }
}

resource "aws_instance" "vault" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_c.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Vault"
  }
}

resource "aws_instance" "hashicorp" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_c.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "HashiCorp"
  }
}

resource "aws_instance" "infoblox" {
  ami                    = data.aws_ami.infoblox.id
  instance_type          = "m5.xlarge"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "my_public_ssh_key"

  tags = {
    Name = "Infoblox"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

}