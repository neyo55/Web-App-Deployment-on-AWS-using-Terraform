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
