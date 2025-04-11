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
echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html

echo "User data script execution completed at $(date)"
