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
