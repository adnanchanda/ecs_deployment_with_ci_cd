
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
}

resource "aws_iam_policy_attachment" "ecs_task_execution_attachment" {
  name       = "ecs_task_execution_attachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn 
  
  container_definitions = jsonencode([{
    name  = "ecs-container"
    image = "${aws_ecr_repository.foo.repository_url}:latest"  
    portMappings = [
      {
        containerPort = 69
        hostPort      = 69
      }
    ]
  }])
}


resource "aws_ecs_cluster" "adnan_cluster" {
  name = "adnan_cluster"
}


resource "aws_ecs_service" "my_ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.adnan_cluster.arn
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 2  

  network_configuration {
    subnets          = ["subnet-03ebaf67fc05d4b1f", "subnet-0dce8a72fb8ae6840"]
    security_groups  = ["sg-084015c7ed23fc703"]
    assign_public_ip = true
  }
}
