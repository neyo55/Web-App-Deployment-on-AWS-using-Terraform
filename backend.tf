terraform {
  backend "s3" {
    bucket         = "neyo-web-server-bucket"  # Change to your actual bucket name
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
