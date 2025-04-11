variable "region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair (without .pem)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
}

variable "subnet_cidr_a" {
  description = "CIDR block for first subnet"
  type        = string
}

variable "subnet_cidr_b" {
  description = "CIDR block for second subnet"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "ami_id" {
  description = "Amazon Machine Image (AMI) ID for the EC2 instance"
  type        = string
}







# variable "region" {
#   description = "AWS region"
#   default     = "eu-west-1"
# }

# variable "instance_type" {
#   description = "EC2 instance type"
#   default     = "t2.micro"
# }

# variable "key_name" {
#   description = "Name of the SSH key pair"
# }

# variable "vpc_cidr" {
#   description = "VPC CIDR Block"
#   default     = "10.0.0.0/16"
# }

# variable "subnet_cidr" {
#   description = "Subnet CIDR Block"
#   default     = "10.0.1.0/24"
# }

# variable "availability_zone" {
#   description = "The Availability Zone where the subnet will be created"
#   default     = "eu-west-1a"  # Change to your preferred region’s AZ
# }

# variable "ami_id" {
#   description = "Amazon Machine Image (AMI) ID for the EC2 instance"
#   default     = "ami-03fd334507439f4d1"  
# }

