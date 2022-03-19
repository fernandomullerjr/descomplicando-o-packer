variable "aws_region" {
  type        = string
  description = ""
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = ""
  default     = "fernandomuller"
}

variable "hostname" {
  type        = string
  description = "Name of host"
  default     = "phoenix"
}

variable "instance_type" {
  type        = string
  description = "AWS EC2 Instance type"
  default     = "t3.micro"
}
