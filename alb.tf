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














# resource "aws_lb" "web_alb" {
#   name               = "web-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.web_sg.id]
#   subnets            = [aws_subnet.web_subnet_a.id, aws_subnet.web_subnet_b.id]

#   enable_deletion_protection = false
# }

# # SSL Certificate from AWS ACM
# resource "aws_acm_certificate" "ssl_cert" {
#   domain_name       = "neyothetechguy.com.ng"
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Load Balancer Target Group
# resource "aws_lb_target_group" "web_tg" {
#   name     = "web-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

# # Redirect HTTP to HTTPS (Listener on Port 80)
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.web_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

# # HTTPS Listener on Port 443
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.web_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.ssl_cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_tg.arn
#   }
# }

# # Attach EC2 Instances to Target Group
# resource "aws_lb_target_group_attachment" "web" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id        = aws_instance.web.id
#   port             = 80
# }






















# resource "aws_lb" "web_alb" {
#   name               = "web-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.web_sg.id]
#   subnets            = [aws_subnet.web_subnet_a.id, aws_subnet.web_subnet_b.id]

#   enable_deletion_protection = false
# }

# resource "aws_lb_target_group" "web_tg" {
#   name     = "web-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.web_alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_tg.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "web" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id        = aws_instance.web.id
#   port             = 80
# }

