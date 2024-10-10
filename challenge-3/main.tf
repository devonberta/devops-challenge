# Fetch the latest Ubuntu AMI


# VPC, Subnets, and NAT Gateway Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"
  name               = "${var.deployment.name-prefix}-vpc"
  cidr               = var.deployment.vpc-cidr
  azs                = ["${var.deployment.region}a", "${var.deployment.region}b", "${var.deployment.region}c"]
  public_subnets     = var.deployment.public-cidrs
  private_subnets    = var.deployment.private-cidrs
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
}

// Create ALB and security group rules
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.11.0"
  vpc_id = module.vpc.vpc_id
  name               = "${var.deployment.name-prefix}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  enable_deletion_protection = false
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }
}
resource "aws_lb_target_group" "asg" {
  name_prefix = "asg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
}

resource "aws_alb_listener" "application_listener" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.asg.arn
    type             = "forward"
  }
}

// Create Autoscale group and launch template to setup apache2 in ubuntu image
resource "aws_security_group" "instance_sg" {
  name        = "${var.deployment.name-prefix}-instance-sg"
  description = "Security group for EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "apache2" {
  name          = "${var.deployment.name-prefix}-apache2-config"
  //image_id      = "ami-df5de72bdb3b"
  image_id      = data.aws_ami.ubuntu-image.id
  instance_type = "t2.micro"
  user_data = base64encode(file("${path.module}/user-data.sh"))
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity          = var.deployment.starting-instances
  health_check_type         = "ELB"
  health_check_grace_period = 300
  max_size                  = var.deployment.max-instances
  min_size                  = var.deployment.min-instances
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns         = [aws_lb_target_group.asg.arn]
  launch_template {
    id      = aws_launch_template.apache2.id
    version = "$Latest"
  }

}

// Create RDS Subnet, Security Group, and Deployment
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.deployment.name-prefix}-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.deployment.name-prefix}-rds-subnet-group"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.9.1"
  apply_immediately      = true
  database_name          = "${var.deployment.name-prefix}db"
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  engine                 = "aurora-mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.small"
  //vpc_security_group_ids = [aws_security_group.rds_sg.id]
  master_username        = "admin"
  master_password        = var.db_password
  name                   = lower(var.deployment.name-prefix)
  vpc_id = module.vpc.vpc_id
  skip_final_snapshot   = true
  security_group_rules  = {
    ingress = {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    egress = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

// Create S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.deployment.name-prefix}-bucket"
  tags = {
    Name = "${var.deployment.name-prefix}-s3"
  }
}
