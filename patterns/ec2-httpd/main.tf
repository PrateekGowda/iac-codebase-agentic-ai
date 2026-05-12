data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "ssm" {
  name = "example-workload-${var.environment}-ec2-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "example-workload-${var.environment}-ec2-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_security_group" "httpd" {
  name        = "example-workload-${var.environment}-httpd"
  description = "Allow HTTP access to the generated EC2 HTTPD instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "httpd" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.small"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.httpd.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -eux
    dnf install -y httpd
    systemctl enable --now httpd
    echo "Hello from example-workload ${var.environment}" > /var/www/html/index.html
  USERDATA

  tags = {
    Name = "example-workload-${var.environment}-httpd"
  }
}

output "http_url" {
  value = "http://${aws_instance.httpd.public_ip}"
}

output "access_method" {
  value = "Use AWS Systems Manager Session Manager. No private SSH key is committed to GitHub."
}
