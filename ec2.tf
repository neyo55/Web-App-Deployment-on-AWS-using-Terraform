resource "aws_instance" "web" {
  depends_on            = [aws_security_group.web_sg]  # Ensure security group is ready so the instance can make use of it 
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.web_subnet_a.id
  user_data              = file("user-data.sh")
  tags = {
    Name = "Terraform-Web-Server"
  }
}
