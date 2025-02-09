# luit-terraform-project2
This project was done in three parts each with increasing difficulty. Please check the main.tf files for the code for this project. My variables.tf file is not part of this file for security reasons


```markdown
# AWS Infrastructure with Terraform

This Terraform configuration sets up a complete AWS infrastructure with a Virtual Private Cloud (VPC), subnets, internet and NAT gateways, security groups, an autoscaling group, an Application Load Balancer (ALB), and a launch template for EC2 instances.

## 1. Provider Configuration
The configuration specifies AWS as the cloud provider and sets the region to `us-east-1`.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

## 2. VPC and Subnets

### VPC
A VPC is created with a CIDR block of `10.0.0.0/16`.

```hcl
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}
```

### Public Subnets
Two public subnets are created in different availability zones (`us-east-1a` and `us-east-1b`) with auto-assign public IP enabled.

```hcl
resource "aws_subnet" "public_subnet_1" { ... }
resource "aws_subnet" "public_subnet_2" { ... }
```

### Private Subnets
Two private subnets are created in different availability zones.

```hcl
resource "aws_subnet" "private_subnet_1" { ... }
resource "aws_subnet" "private_subnet_2" { ... }
```

## 3. Internet and NAT Gateways

### Internet Gateway
An Internet Gateway is attached to the VPC to allow public subnets to access the internet.

```hcl
resource "aws_internet_gateway" "my_igw" { ... }
```

### NAT Gateway
Two NAT Gateways (one in each AZ) are created to allow private subnets to access the internet.

```hcl
resource "aws_nat_gateway" "nat_az1" { ... }
resource "aws_nat_gateway" "nat_az2" { ... }
```

## 4. Route Tables and Associations

### Public Route Table
A route table is created for public subnets with a default route to the Internet Gateway.

```hcl
resource "aws_route_table" "public_rt" { ... }
```

### Private Route Tables
Each private subnet is associated with a separate route table that routes internet-bound traffic through a NAT Gateway.

```hcl
resource "aws_route_table" "private_rt_az1" { ... }
resource "aws_route_table" "private_rt_az2" { ... }
```

## 5. Security Groups

### Application Security Group
Allows inbound HTTP, HTTPS, and SSH traffic from the ALB security group and all outbound traffic.

```hcl
resource "aws_security_group" "my-luit-sg" { ... }
```

### ALB Security Group
Allows inbound HTTP, HTTPS, and SSH traffic from any IP and all outbound traffic.

```hcl
resource "aws_security_group" "luit-alb-sg" { ... }
```

## 6. Launch Template

A launch template is created with:
- AMI ID: `ami-04b4f1a9cf54c11d0`
- Instance type: `t2.micro`
- A user data script that installs and starts Apache.

```hcl
resource "aws_launch_template" "luit-launch-template" { ... }
```

## 7. Auto Scaling Group

An Auto Scaling Group (ASG) is created with:
- Minimum 2 instances, maximum 5
- Instances launched in private subnets
- Connected to a target group for load balancing

```hcl
resource "aws_autoscaling_group" "luit-asg" { ... }
```

## 8. Load Balancer and Target Group

### Target Group
The ALB target group is configured to route HTTP traffic to instances.

```hcl
resource "aws_alb_target_group" "luit-tg" { ... }
```

### Application Load Balancer
An ALB is created in the public subnets, associated with its security group.

```hcl
resource "aws_lb" "luit-alb" { ... }
```

### Listener
The ALB listener forwards HTTP requests to the target group.

```hcl
resource "aws_lb_listener" "luit-alb-listener" { ... }
```

## 9. Output

The DNS name of the ALB is output for easy access.

```hcl
output "luit-alb-dns" {
  value = aws_lb.luit-alb.dns_name
}
```

---

## Summary

This Terraform configuration sets up:
✅ A secure AWS VPC  
✅ Public and private subnets across two availability zones  
✅ Internet Gateway for public access  
✅ NAT Gateway for private subnet internet access  
✅ Route tables to manage network traffic  
✅ Security groups for instances and ALB  
✅ A launch template for EC2 instances running Apache  
✅ An Auto Scaling Group for high availability  
✅ An Application Load Balancer for traffic distribution  

