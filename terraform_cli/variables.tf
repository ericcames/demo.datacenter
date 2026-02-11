# AMI-related variables

variable "rhel10_ami_name" {
  description = "Search string for RHEL 10 AMI"
  type        = string
  default     = "RHEL-10.1*Hourly*"
}

variable "rhel9_ami_name" {
  description = "Search string for RHEL 9 AMI"
  type        = string
  default     = "RHEL-9.4*Hourly*"
}

variable "rhel8_ami_name" {
  description = "Search string for RHEL 8 AMI"
  type        = string
  default     = "RHEL-8.10*Hourly*"
}

variable "rhel_arch" {
  description = "CPU architecture to use for RHEL AMI"
  type        = string
  default     = "x86_64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.rhel_arch)
    error_message = "Valid values are 'x86_64' or 'arm64'"
  }
}

variable "f5_ami_name" {
  description = "Search string for F5 21 AMI"
  type        = string
  default     = "F5 BIGIP-21.0.0.1-0.0.13 PAYG-Better 1Gbps*"
}

variable "infoblox_ami_name" {
  description = "Search string for InfoBlox AMI"
  type        = string
  default     = "*LTSPayGo*"
}

variable "panos_ami_name" {
  description = "Search string for Palo Alto AMI"
  type        = string
  default     = "PA-VM-AWS-11.1.13-*"
}
