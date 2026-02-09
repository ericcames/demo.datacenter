variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "learn-terraform"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
  default     = "t2.micro"
}

variable "f5_ami" {
  description = "AMI ID for the F5."
  type        = string
  default     = "ami-0a6612e49a32df1e9"
}
