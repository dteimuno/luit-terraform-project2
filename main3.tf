provider "aws" {
  region = "us-east-1"

}
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

#internet gateway attached to the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}
#  Public Route Table 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  # Route for outbound traffic to the internet via the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

#  Associate Public Route Table with Public Subnets in us-east-1a and us-east-1b
resource "aws_route_table_association" "public_rt_assoc_az1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_az2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

#  Private Route Table for private subnet1 
resource "aws_route_table" "private_rt_az1" {
  vpc_id = aws_vpc.my_vpc.id

  # Route for outbound traffic to the internet via NAT Gateway in AZ-1
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_az1.id
  }
}

#  Private Route Table for private subnet2 
resource "aws_route_table" "private_rt_az2" {
  vpc_id = aws_vpc.my_vpc.id

  # Route for outbound traffic to the internet via NAT Gateway in AZ-2
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_az2.id
  }
}

#  Associate Private Route Tables with Private Subnets in AZ-1 and AZ-2
resource "aws_route_table_association" "private_rt_assoc_az1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

resource "aws_route_table_association" "private_rt_assoc_az2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_az2.id
}


#Create NAT gateway in the public subnet
#  Elastic IP for NAT Gateway in AZ-1
resource "aws_eip" "nat_eip_az1" {
}

#  Elastic IP for NAT Gateway in AZ-2
resource "aws_eip" "nat_eip_az2" {
}

#  NAT Gateway for AZ-1
resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_eip_az1.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

#  NAT Gateway for AZ-2
resource "aws_nat_gateway" "nat_az2" {
  allocation_id = aws_eip.nat_eip_az2.id
  subnet_id     = aws_subnet.public_subnet_2.id
}


#Create a security group that allows HTTP, HTTPS, SSH inbound traffic and all outbound traffic
resource "aws_security_group" "my-luit-sg" {
  name        = "my-luit-sg"
  description = "Allow all inbound HTTP, HTTPS, and SSH traffic"
  vpc_id      = aws_vpc.my_vpc.id
}
resource "aws_security_group_rule" "asg-ingress-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my-luit-sg.id
  source_security_group_id = aws_security_group.luit-alb-sg.id
}

#rules for the asg security group
resource "aws_security_group_rule" "asg-ingress-https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my-luit-sg.id
  source_security_group_id = aws_security_group.luit-alb-sg.id
}

resource "aws_security_group_rule" "asg-ingress-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my-luit-sg.id
  source_security_group_id = aws_security_group.luit-alb-sg.id
}

resource "aws_security_group_rule" "asg-egress-all" {
  type              = "egress"
  from_port         = 20
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my-luit-sg.id
}

#ALB security group that allows HTTP inbound traffic and all outbound traffic
resource "aws_security_group" "luit-alb-sg" {
  name        = "luit-alb-sg"
  description = "Allow all inbound HTTP traffic "
  vpc_id      = aws_vpc.my_vpc.id
}

#rules for the ALB security group
resource "aws_security_group_rule" "alb-ingress-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.luit-alb-sg.id
}

resource "aws_security_group_rule" "alb-ingress-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.luit-alb-sg.id
}

resource "aws_security_group_rule" "alb-ingress-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.luit-alb-sg.id
}

resource "aws_security_group_rule" "alb-egress-all" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.luit-alb-sg.id
  source_security_group_id = aws_security_group.my-luit-sg.id
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
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo systemctl enable apache2
    EOF
  )
}

#Create an autoscaling group with the following configuration with security group only accepting traffic from the ALB:

resource "aws_autoscaling_group" "luit-asg" {
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  force_delete              = true
  launch_template {
    id      = aws_launch_template.luit-launch-template.id
    version = "$Latest"
  }
  target_group_arns = [aws_alb_target_group.luit-tg.arn]
}

#Create a target group with the following configuration:  
resource "aws_alb_target_group" "luit-tg" {
  name             = "luit-tg"
  port             = 80
  protocol         = "HTTP"
  vpc_id           = aws_vpc.my_vpc.id
  protocol_version = "HTTP1"
  target_type      = "instance"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}



#Create an Application Load Balancer with the following configuration:
resource "aws_lb" "luit-alb" {
  name               = "luit-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.luit-alb-sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  ip_address_type    = "ipv4"

  enable_deletion_protection = false
}

#Create a listener for the ALB that listens on port 80 and forwards traffic to the target group
resource "aws_lb_listener" "luit-alb-listener" {
  load_balancer_arn = aws_lb.luit-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.luit-tg.arn
  }
}

#output the DNS name of the ALB
output "luit-alb-dns" {
  value = aws_lb.luit-alb.dns_name
}
