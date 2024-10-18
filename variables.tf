variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-west-2"
}

variable "availability_zone" {
  description = "The availability zone to create the subnet in"
  type        = string
  default     = "us-west-2a"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "prefix" {
  type = string
}

variable "namespace_id" {
  description = "Your Temporal Cloud namespace ID"
  type        = string
}

variable "account_id" {
  description = "Your Temporal Cloud account ID"
  type        = string
}