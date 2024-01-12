resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "Application"
    from_port   = 8000
    to_port     = 8000
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
    Name = "Web-sg"
  }
}

resource "aws_dynamodb_table" "candidate-table" {
  name         = "Candidates"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CandidateName"

  attribute {
    name = "CandidateName"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  lifecycle {
    ignore_changes = [
      ttl
    ]
  }
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "EC2_DynamoDB_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDB_Access_Policy"
  description = "Policy for EC2 instances to access DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "dynamodb:BatchGetItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      Effect   = "Allow",
      Resource = aws_dynamodb_table.candidate-table.arn
    }]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "dynamodb_attachment" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role       = aws_iam_role.ec2_role.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_Instance_Profile"
  role = aws_iam_role.ec2_role.name
}

# Update EC2 Instances to use IAM Instance Profile
resource "aws_instance" "webserver1" {
  ami                    = "ami-05fb0b8c1424f266b"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-05fb0b8c1424f266b"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub2.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 8000
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}
