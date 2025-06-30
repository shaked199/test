provider "aws" {
  region = "il-central-1"
}

variable "cluster_name" {
  default = "shaked-imtech"#change to the cluster name
}

variable "lb_target_group_arn" {
  description = "ARN of existing ALB Target Group"
  default     = "arn:aws:elasticloadbalancing:il-central-1:123456789012:targetgroup/my-target-group/abc1234567890def"
}
# the subnets of the ecs
variable "subnet_ids" {
  description = "List of private subnets for ECS task"
  type        = list(string)
  default     = ["subnet-01e6348062924d048",
    "subnet-0a1cbd99dd27a5307",
    "subnet-0d0b0b1b77639731b",
    "subnet-088b7d937a4cd5d85"] #<-- the subnets id we worked on the imtech aws 
}

# the security group of the ecs the sg below is the sg of the imtech aws
variable "security_group_id" {
  description = "Security group for ECS tasks"
  default     = "sg-0ac3749215afde82a"
}
variable "load_balancer_arn" {
  description = "ARN of the existing Application Load Balancer"
  default     = "arn:aws:elasticloadbalancing:il-central-1:123456789012:loadbalancer/app/my-alb/abc123"
}
variable "image" {
  description = "Docker image name with tag"
  type        = string
}


resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-task"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "256"
  memory                  = "512"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "fluentd"
        options = {
          "fluentd-address" = "172.29.80.10:6789"
          "tag"             = "nginx"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = var.cluster_name
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.nginx.arn

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_ecs_task_definition.nginx]
}
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = var.load_balancer_arn
  port              = 9988
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.lb_target_group_arn
  }
}
