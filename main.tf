provider "aws" {
  region = "us-east-1"

}

#Create a security group that allows HTTP, HTTPS, SSH inbound traffic and all outbound traffic
resource "aws_security_group" "my-luit-sg" {
  name        = "my-luit-sg"
  description = "Allow all inbound HTTP, HTTPS, and SSH traffic"

  vpc_id = var.default-vpc_id # default-vpc_id is defined in variables.tf

  # Ingress rules
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all HTTPS traffic"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all HTTP traffic"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all SSH traffic"
  }

  # Egress rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

}




#Create launch template with the following configuration:
resource "aws_launch_template" "luit-launch-template" {
  name                   = "luit-launch-template"
  image_id               = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.my-luit-sg.id]
  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    EOF
  )
}

#Create an autoscaling group with the following configuration:

resource "aws_autoscaling_group" "luit-asg" {
  availability_zones        = ["us-east-1a", "us-east-1b"]
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  force_delete              = true

  launch_template {
    id      = aws_launch_template.luit-launch-template.id
    version = "$Latest"
  }
}
