resource "aws_instance" "web" {
  count = 2

  ami                    = "ami-08943a151bd468f4e"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.web[count.index].id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tags = {
    Name = "${var.domain_name}-web-${count.index + 1}"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.domain_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = {
    Name = "${var.domain_name}-ec2-profile"
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.domain_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.domain_name}-ec2-ssm-role"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count = 2

  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}