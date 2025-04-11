# **Deployment of a Web App on AWS using Terraform**
---
## **Introduction**
This readme provides a **step-by-step** approach to deploying a **highly available** and **auto-scaling web application** on AWS using Terraform. This readme is designed to be **beginner-friendly**, ensuring that anyone can follow the steps and set up the infrastructure.

## **Infrastructure Overview**
Using Terraform, this setup will create:
✅ **VPC with public subnets**  
✅ **Security groups** for secure access  
✅ **Application Load Balancer (ALB)**  
✅ **Auto Scaling Group (ASG)** for handling traffic spikes  
✅ **CloudWatch Alarms** for monitoring and automatic scaling  
✅ **S3 for Terraform remote state storage**  
✅ **DynamoDB for state locking** to prevent conflicts  

---

## **Directory Structure**
```
terraform-web-app/
│── network.tf          # Main Terraform configuration
│── variables.tf        # Input variables
│── outputs.tf          # Outputs
│── security.tf         # Security group
│── alb.tf              # Application Load Balancer
│── ec2.tf              # EC2 instance and provisioning
│── provider.tf         # AWS provider configuration
│── user-data.sh        # Script to set up web server
│── terraform.tfvars    # Variable values
│── autoscaling.tf      # Auto Scaling configuration
│── backend.tf          # Backend configuration for Terraform state
│── s3-bucket/
        │── provider.tf  # Provider for S3/DynamoDB
        │── s3.tf        # S3 bucket for remote state
        │── dynamodb.tf  # DynamoDB table for state locking
        │── provider.tf  # AWS provider configuration
        │── variable.tf  # Input variable for the region only
        │── terraform.tfvars     # Variable value
```
---

## **Prerequisites**
Before running the setup, ensure you have:
- **Terraform installed** (`terraform -v`)
- **AWS CLI configured** (`aws configure`)
- **An AWS account** with IAM access

---

## **Step 1: Set Up Remote State Storage (S3 + DynamoDB)**
Terraform state must be stored in an **S3 bucket** with a **DynamoDB table for state locking**.

### **1️⃣ Define AWS Provider for S3 & DynamoDB**
 **`s3-bucket/provider.tf`**
```hcl
provider "aws" {
  region = var.region
}
```

 **`s3-bucket/variable.tf`**
```hcl
variable "region" {
  description = "AWS region"
  type     = "string"
}
```

 **`s3-bucket/terraform.tfvars`**
```hcl
region = "eu-west-1"
```

### **1️⃣ Create the S3 bucket**
In `s3-bucket/s3.tf`:
```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "neyo-web-server-bucket"  # Replace with your unique bucket name
  force_destroy = true  # Deletes bucket when running `terraform destroy`

  tags = {
    Name        = "neyo-web-server-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

```

### **2️⃣ Create the DynamoDB Table**
In `s3-bucket/dynamodb.tf`:
```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Dev"
  }
}


```

### **3️⃣ Apply the S3 & DynamoDB Setup**
Navigate to `s3-bucket/` directory and run:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## **🔗 Step 2: Configure Terraform Backend**

Navigate back to the main directory `terraform-web-app` to proceed. Edit the `.tf` files accordingly.

 **`terraform-web-app/provider.tf`**
```hcl
provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0" # Terraform CLI version
}
```

 **`terraform-web-app/variable.tf`**
```hcl
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
```

 **`terraform-web-app/terraform.tfvars`**
```hcl
ami_id             = "ami-03fd334507439f4d1"
region             = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b"] # Use two AZs in your region for the load balancer
instance_type      = "t2.micro"
key_name           = "server-key" # Replace with your actual key pair name
vpc_cidr           = "10.0.0.0/16"
subnet_cidr_a      = "10.0.1.0/24"
subnet_cidr_b      = "10.0.2.0/24"
```

Edit `backend.tf` in `terraform-web-app/` to use the **S3 backend**:
```hcl
terraform {
  backend "s3" {
    bucket         = "neyo-web-server-bucket"  # Change to your actual bucket name
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

---

## **Step 3: Create the Network Infrastructure**
In `network.tf`, define the **VPC and subnets**:
```hcl
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
```

---

## **Step 4: Configure Security Groups**
In `security.tf`, define rules to **allow HTTP, HTTPS and SSH traffic**:
```hcl
# Create a security group for web server
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow inbound traffic for web app"
  vpc_id      = aws_vpc.main.id

# Add HTTP ingress rule
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Adding ingress rule for port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Add SSH ingress rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Add HTTPS ingress rule
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Add egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## **Step 5: Create the Application Load Balancer**
In `alb.tf`:
```hcl
# Load Balancer (ALB)
resource "aws_lb" "web_alb" {
  depends_on = [aws_security_group.web_sg]
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.web_subnet_a.id, aws_subnet.web_subnet_b.id]

  enable_deletion_protection = false
}

# Load Balancer Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Redirect HTTP to HTTPS (Listener on Port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener on Port 443 using the ISSUED ACM Certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-west-1:509590356409:certificate/aae858cd-652d-46dd-bbcf-7541e9b2f355"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Attach EC2 Instances to Target Group
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}
```

---

## **Step 6: Launch EC2 Instances**
In `ec2.tf`:
```hcl
resource "aws_instance" "web" {
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
```
---
**user-data.sh** This will be installed on the instance and also on the scaled instances too.

```bash
#!/bin/bash

# Log file for debugging
LOG_FILE="/var/log/user-data.log"

exec > >(tee -a $LOG_FILE) 2>&1

echo "Starting user data script at $(date)"

# Update and upgrade packages
echo "Updating packages..."
apt update -y 

# Install Apache
echo "Installing Apache..."
apt install -y apache2

# Install AWS CLI
echo "Installing AWS CLI..."
apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install || echo "AWS CLI installation failed"

# Install Certbot for SSL
echo "Installing Certbot..."
apt install -y certbot python3-certbot-apache

# Installing system state
echo "Installing system state..."
sudo apt install -y sysstat

# Ensure Apache is restarted after Certbot install
echo "Restarting Apache..."
systemctl restart apache2
systemctl enable apache2

# Deploy Web Content
echo "Deploying web content..."
echo "<h1>Deployed via Terraform 🚀</h1>" > /var/www/html/index.html

echo "User data script execution completed at $(date)"

```
---
## **Step 7: Configure Auto Scaling**
In `autoscaling.tf`:
```hcl
# Auto Scaling Group with Launch Template and Policies
resource "aws_launch_template" "web_launch_template" {
  name_prefix            = "web-lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(file("user-data.sh")) # Ensure Apache auto-configures on launch

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "AutoScaling-Instance"
    }
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.web_subnet_a.id, aws_subnet.web_subnet_b.id]
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "AutoScaling-Web-Instance"
    propagate_at_launch = true
  }
}

# Autoscaling Policies (increase the number of instances by 1 when CPU utilization is high)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

# Autoscaling Policies (decrease the number of instances by 1 when CPU utilization is low)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

# Scale-Out Alarm (Add Instance when CPU > 30%)
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "ScaleOutAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

# Scale-In Alarm (Remove Instance when CPU < 20%)
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "ScaleInAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}
```
---
## **The output details of the Deployment**
In `output.tf`:
```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
```
---

## **Final Step: Deploy Everything**
Now, navigate to `terraform-web-app/` and run but make sure the s3 and DynamoDB ic created first:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
Once deployed, check the **Load Balancer DNS**:
```bash
echo "http://$(terraform output alb_dns)"
```
---

# **🔹 Understanding Auto Scaling Policies Clearly**
Auto Scaling is controlled by **scaling policies** that determine when to **add** or **remove** instances based on CloudWatch alarms.

Let’s break it down so you fully understand **what happens when you trigger CPU stress**.

---

### **Auto Scaling Configuration**
From what we've set up, your **Auto Scaling Group (ASG)**:
- **Min Instances:** `1`  
- **Max Instances:** `4`  
- **Desired Capacity:** `2`  
- **Scaling Policies:**
  - **Scale-Out Policy (Increase Instances)**  
    🔹 If **CPU > 30%** for **1 evaluation period (60 sec)** → **Launch a new instance**
  - **Scale-In Policy (Reduce Instances)**  
    🔹 If **CPU < 20%** for **2 evaluation periods (120 sec)** → **Terminate an instance**

---

### **What Happens When `stress` is ran `stress --cpu 4 --timeout 120` on the default instance?**

**SSH into your instance with your `SSH` key**
```bash
ssh -i server-key.pem ubuntu@<EC2-PUBLIC-IP>
```

Run this command on the terminal of your instance to stress the `CPU`
```bash
stress --cpu 4 --timeout 120
```
1️⃣ **Step 1: CPU Usage Rises**  
   - The `stress --cpu 4 --timeout 120` command **simulates high CPU load** for **120 seconds**.
   - The CloudWatch alarm **measures CPU utilization every 60 seconds**.

2️⃣ **Step 2: CloudWatch Triggers Scale-Out**  
   - If **CPU > 30%**, the `"ScaleOutAlarm"` changes to `"ALARM"`.
   - CloudWatch **notifies Auto Scaling** to launch a new instance.
   - **A new instance is created** (appears in EC2 console within a few minutes).

3️⃣ **Step 3: CPU Load Returns to Normal**  
   - After 120 seconds, the stress test stops, and CPU usage **gradually decreases**.
   - The `"ScaleOutAlarm"` returns to `"OK"`.

4️⃣ **Step 4: CloudWatch Triggers Scale-In**  
   - If CPU drops **below 20% for 2 evaluation periods (120 sec)**:
   - The `"ScaleInAlarm"` enters `"ALARM"` state.
   - Auto Scaling **removes an instance** (moves to `Terminating` state).
   - **It gradually disappears from the EC2 instance list**.

---

### **🔹 Expected Outcome from Your Test**
🔹 **If you run `stress --cpu 4 --timeout 120` on 1 instance:**

✔️ CPU **rises above 30%** → Auto Scaling **adds a new instance**  
✔️ After 120 sec, stress stops → CPU **drops below 20%**  
✔️ Auto Scaling waits **2 evaluation periods (120 sec)** before **removing an instance**  

---

### **How to Monitor Everything in Real-Time**
While testing, monitor these:

✔️ **Check CloudWatch Alarm State:**
```bash
aws cloudwatch describe-alarms --region eu-west-1 --query "MetricAlarms[*].[AlarmName,StateValue]"
```
- `"ALARM"` on `"ScaleOutAlarm"` → Scaling **adds** an instance.
- `"ALARM"` on `"ScaleInAlarm"` → Scaling **removes** an instance.

✔️ **Check Auto Scaling Instances:**
```bash
aws autoscaling describe-auto-scaling-instances --region eu-west-1
```
- **New instance appears during Scale-Out**.
- **Instance moves to `Terminating` state during Scale-In**.

---

### **Summary**
✅ **Auto Scaling adds instances when CPU rises above 30%.**  
✅ **It removes instances when CPU drops below 20%.**  
✅ **Scaling takes a few minutes to process.**  

Try triggering the **stress test on your instance to understand it**, monitor the behavior and confirm it works.


---

#### **1️⃣ Run the Stress Test with Higher CPU Load**
- **If your instance type is `t2.micro`, it has only 1 vCPU**.  
  - Use **`--cpu 1` on multiple instances at the same time**.
run:  
  ```bash
  stress --cpu 1 --timeout 180
  ```

- **If your instance type has more vCPUs (`t3.medium`, `c5.large`, etc.)**, you can run:  
  ```bash
  stress --cpu 16 --timeout 180
  ```
  or  
  ```bash
  stress --cpu 24 --timeout 180
  ```
  - This will **saturate the CPU usage** for **3 minutes**.

---

### **Expected Observations**
✔️ **Health Check Behavior**  
   - If CPU is **fully maxed out**, **instances may fail ALB health checks**.
   - Instances with high CPU usage **might show as "Unhealthy"** in **EC2 -> Target Groups**.
   - ALB may **stop routing traffic** to unhealthy instances.

✔️ **Auto Scaling Reaction**  
   - CloudWatch should detect **CPU > 30%** and **keep adding instances** until the max limit (`max_size`) is reached.
   - Check the **number of instances Auto Scaling creates** using:
     ```bash
     aws autoscaling describe-auto-scaling-instances --region eu-west-1
     ```
   - Monitor CloudWatch alarms to see `"ScaleOutAlarm"` triggering:
     ```bash
     aws cloudwatch describe-alarms --region eu-west-1 --query "MetricAlarms[*].[AlarmName,StateValue]"
     ```

---

### **What to Do After the Test**
After you finish testing:
1️⃣ **Stop the Stress Test**  
   ```bash
   sudo killall stress
   ```

2️⃣ **Monitor Scale-In**  
   - Auto Scaling will **start removing instances** if CPU drops below 20%.
   - Check if instances **gradually terminate**:
     ```bash
     aws autoscaling describe-auto-scaling-instances --region eu-west-1
     ```

### **Make sure you delete the project after successful testing to avoid charges from AWS**
After you finish testing:
1️⃣ **Command to delete the project**  
   ```bash
   terraform destroy -auto-approve
   ```
**This will delete the project and all resources created**
---

### **Summary**
✅ **Increasing CPU stress tests max Auto Scaling behavior.**  
✅ **ALB health checks may mark instances "Unhealthy" if overloaded.**  
✅ **Auto Scaling will keep adding instances until max capacity is reached.**  




## **Conclusion**
You have successfully deployed a **highly available**, **auto-scaling** web application using Terraform on AWS and also testing the autoscaling function with Alarm trigger capabilities.

---

## **Possble addition to make your setup robust**
- Implement **SSL/TLS** using **Cloudflare and AWS ACM**. [AWS ACM/Cloudflare Setup](./aws-acm.md)
- Improve security with **IAM roles and policies**. [S3 Bucket with IAM Roles and Policies](./s3-bucket-setup.md)
- Set up **monitoring with CloudWatch metrics**. [Autoscaling/ CloudWatch Setup](./autoscaling.md)


