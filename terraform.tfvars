ami_id             = "ami-03fd334507439f4d1"
region             = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b"] # Use two AZs in your region for the load balancer
instance_type      = "t2.micro"
key_name           = "server-key" # Replace with your actual key pair name
vpc_cidr           = "10.0.0.0/16"
subnet_cidr_a      = "10.0.1.0/24"
subnet_cidr_b      = "10.0.2.0/24"
