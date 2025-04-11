
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main-VPC"
  }
}

# Create Subnet
resource "aws_subnet" "web_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_a
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[0]

  tags = {
    Name = "Web-Subnet-A"
  }
}

resource "aws_subnet" "web_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_b
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[1]

  tags = {
    Name = "Web-Subnet-B"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Web-IGW"
  }
}

# Route Table
resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Web-Route-Table"
  }
}


# Route Table Association
resource "aws_route_table_association" "web_rta_a" {
  subnet_id      = aws_subnet.web_subnet_a.id
  route_table_id = aws_route_table.web_rt.id
}

resource "aws_route_table_association" "web_rta_b" {
  subnet_id      = aws_subnet.web_subnet_b.id
  route_table_id = aws_route_table.web_rt.id
}















































# resource "aws_subnet" "web_subnet" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true
#   availability_zone       = var.availability_zones[0]

#   tags = {
#     Name = "Web-Subnet"
#   }
# }