data "aws_ami" "ubuntu" {
  most_recent = true
  owners = [
    "099720109477",
    "self"
  ]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_ami" "win25" {
  most_recent = true
  owners = [
    "801119661308",
    "self"
  ]
  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }
}

data "aws_ami" "rhel8" {
  most_recent = true
  owners = [
    "309956199498",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.rhel8_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}

data "aws_ami" "rhel9" {
  most_recent = true
  owners = [
    "309956199498",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.rhel9_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}

data "aws_ami" "rhel10" {
  most_recent = true
  owners = [
    "309956199498",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.rhel10_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}

data "aws_ami" "f5_21" {
  most_recent = true
  owners = [
    "679593333241",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.f5_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}

data "aws_ami" "infoblox" {
  most_recent = true
  owners = [
    "679593333241",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.infoblox_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}

data "aws_ami" "panos" {
  most_recent = true
  owners = [
    "679593333241",
    "self"
  ]
  filter {
    name = "name"
    values = [
      var.panos_ami_name
    ]
  }
  filter {
    name = "architecture"
    values = [
      var.rhel_arch
    ]
  }
}
