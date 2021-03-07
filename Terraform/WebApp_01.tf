////////// #IAM Instance Profile //////////
resource "aws_iam_instance_profile" "user-profile" {
  name = "user-profile"
  role = aws_iam_role.user-role.name
}

resource "aws_iam_role" "user-role" {
  name = "user-role"
  path = "/"
  managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonSSMFullAccess" ]
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

////////// #Security Groups //////////
resource "aws_security_group" "app-sg" {
  depends_on = [aws_security_group.alb-sg]
  name        = "app-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc-webapp.id
  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app-sg"
  }
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc-webapp.id
  ingress {
    description = "HTTP open to world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS open to world"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb-sg"
  }
}

////////// #AMI ID //////////
data "aws_ssm_parameter" "linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

////////// #Launch Configuration Template //////////
resource "aws_launch_configuration" "launch-config" {
  depends_on = [ aws_iam_instance_profile.user-profile, aws_security_group.app-sg ]
  name_prefix   = "webapp-launch-config"
  image_id      = data.aws_ssm_parameter.linux.value
  instance_type = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.user-profile.name
  security_groups = [aws_security_group.app-sg.id]
  root_block_device {
      volume_size = "10"
      volume_type = "gp2"
      #encrypted = true
    }
  ebs_block_device {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "10"
      #encrypted = true
      delete_on_termination = true
    }
  metadata_options {
    http_endpoint = "enabled"
  }
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              curl -o /var/www/html/index.html https://raw.githubusercontent.com/Asif-Patel/AWS-WebApp-Hosting-Module/main/demo/index.html
              #echo "Hello Asif! from terraform" >> /var/www/html/index.html
              chkconfig httpd on
              service httpd start
              iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  EOF
}

////////// #Auto-Scaling Group //////////
resource "aws_autoscaling_group" "asg-group" {
  name = "webapp-asg"
  depends_on = [ aws_launch_configuration.launch-config ]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  vpc_zone_identifier = [aws_subnet.pri-subnet-1.id, aws_subnet.pri-subnet-2.id]
  launch_configuration = aws_launch_configuration.launch-config.name
  /*launch_template {
    id      = aws_launch_template.launch-temp.id
    version = "$Latest"
  }*/
  tag {
    key = "Name"
    value = "webapp-asg"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

////////// #Auto-Scaling Group Attachment with Target Group //////////
resource "aws_autoscaling_attachment" "asg-tg-attach" {
  depends_on = [aws_lb_target_group.webapp-tg]
  autoscaling_group_name = aws_autoscaling_group.asg-group.id
  alb_target_group_arn   = aws_lb_target_group.webapp-tg.arn
}

/*resource "aws_lb_target_group_attachment" "asg-tg-attach" {
  target_group_arn = aws_lb_target_group.webapp-tg.arn
  target_id        = aws_autoscaling_group.asg-group.id
  port             = 80
}*/