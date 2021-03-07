////////// #Application Load Balancer //////////
resource "aws_lb" "webapp-alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.pub-subnet-1.id, aws_subnet.pub-subnet-2.id]
  enable_deletion_protection = false
  /*access_logs {
    bucket  = aws_s3_bucket.alb-logs.bucket
    prefix  = "webapp-alb"
    enabled = true
  }*/
  tags = {
    Name = "webapp-alb"
  }
}

////////// #Output for ALB //////////
output "alb-endpoint-URL" {
  depends_on = [aws_lb.webapp-alb]
  value = aws_lb.webapp-alb.dns_name
}

////////// #Target Groups //////////
resource "aws_lb_target_group" "webapp-tg" {
  name     = "webapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-webapp.id
}

////////// #LB Listner //////////
resource "aws_lb_listener" "http_end" {
  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-tg.arn
  }
}

////////// #LB Listner Rule //////////
/*resource "aws_lb_listener" "http_end" {
  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.webapp-cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-tg.arn
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.webapp-alb.arn
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

////////// #WebApp Certificate //////////
resource "aws_acm_certificate" "webapp-cert" {
  domain_name       = "example.com"
  validation_method = "DNS"
  tags = {
    Environment = "test"
  }
  lifecycle {
    create_before_destroy = true
  }
}
*/

////////// #EC2 Monitoring //////////
resource "aws_autoscaling_notification" "ec2_notifications" {
  group_names = [aws_autoscaling_group.asg-group.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_STOP",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.enduser.arn
}

////////// #ALB Monitoring //////////
resource "aws_cloudwatch_metric_alarm" "alb_healthyhosts" {
  alarm_name          = "webapp-monitoring"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationALB"
  period              = "60"
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.enduser.arn]
  ok_actions          = [aws_sns_topic.enduser.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.webapp-tg.arn_suffix
    LoadBalancer = aws_lb.webapp-alb.arn_suffix
  }
}

////////// #SNS Topic //////////
resource "aws_sns_topic" "enduser" {
  name = "user-updates-topic"
}
resource "aws_sns_topic_subscription" "enduser-subscription1" {
  topic_arn = aws_sns_topic.enduser.arn
  protocol  = "email"
  endpoint = "patelasif8600@gmail.com"
  endpoint_auto_confirms = true
}
/*resource "aws_sns_topic_subscription" "enduser-subscription2" {
  topic_arn = aws_sns_topic.enduser.arn
  protocol  = "email"
  endpoint = "suresh.venkata@mastercard.com"
  endpoint_auto_confirms = true
}*/
