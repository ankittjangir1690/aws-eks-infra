resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = var.vpc_id  # Pass the VPC ID from the parent module

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]  # Allow HTTPS from anywhere
  }

  tags = {
    Name = "ALB Security Group"
  }
}

resource "aws_lb" "myapp" {
  name               = "myapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Reference to the security group

  enable_deletion_protection = false
  idle_timeout               = 60
  enable_cross_zone_load_balancing = true

  # Specify the subnets where the ALB will be created
  subnets = var.subnets  # Pass the subnet IDs from the parent module

  tags = {
    Name = "My App ALB"
  }
}

resource "aws_lb_target_group" "myapp_tg" {
  name     = "myapp-target-group"
  port     = 3000  # Port your application listens on
  protocol = "HTTP"
  vpc_id   = var.vpc_id  # Pass the VPC ID from the parent module

  health_check {
    path                = "/health"  # Adjust the health check path as needed
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "My App Target Group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.myapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.myapp.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"  # Adjust SSL policy if needed
  certificate_arn = var.acm_certificate_arn  # Pass your ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}
