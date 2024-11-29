resource "aws_lb" "app" {
  name = "group01-app-hellorails-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ecs.id]
  subnets = [aws_subnet.subnet_public_a.id, aws_subnet.subnet_public_b.id]

  tags = {
    Name = "group01-hellorails-alb"
  }
}

resource "aws_lb_target_group" "ecs" {
  name = "group01-app-hellorails-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}
