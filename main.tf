terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region_name
}





resource "aws_s3_bucket" "sbucket" {
  bucket = var.bucket_name
}



resource "aws_iam_role" "leo_role" {
  name = "leo_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "leo ec2 role"
  }
}

resource "aws_vpc" "cstomVPC" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cstomVPC.id

  tags = {
    Name = "igw"
  }
  }

resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.cstomVPC.id
  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "allow_mysql"
  }
}

resource "aws_security_group" "allow_alb" {
  name        = "allow_alb"
  description = "Allow alb inbound traffic"
  vpc_id      = aws_vpc.cstomVPC.id
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

  tags = {
    Name = "allow_mysql"
  }
}




resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.az1
  tags = {
    Name = "privateSubnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = var.az2
  tags = {
    Name = "privateSubnet2"
  }
}

resource "aws_db_subnet_group" "my_subnet_group" {
  name       = "my_subnet_group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}


resource "aws_subnet" "custom_public_subnet1" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet3_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "publicSubnet1"
  }
}


resource "aws_subnet" "custom_public_subnet2" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "publicSubnet2"
  }
}




/*resource "aws_db_instance" "my_mysql" {
  allocated_storage    = var.storage
  storage_type         = var.dbAllocatedStorage
  engine               = var.dbEngine
  engine_version       = var.engineVersion
  instance_class       = var.dbInstanceClass
  db_name              = var.dbName
  username             = var.dbUsername
  password             = var.dbPassword
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.my_subnet_group.name
  vpc_security_group_ids = [aws_security_group.allow_mysql.id]
  skip_final_snapshot  = true
}*/

# Create an IAM role for AWS Glue


resource "aws_iam_role" "glue_role" {
  name = "aws_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the AWSGlueServiceRole policy to the role
resource "aws_iam_role_policy_attachment" "glue_service_role_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Define the AWS Glue job
resource "aws_glue_job" "example_glue_job" {
  name     = "example-glue-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://my-bucket/scripts/my-glue-script.py"
    python_version  = "3"
  }

  default_arguments = {
    "--TempDir"             = "s3://my-bucket/temp-dir"
    "--job-language"        = "python"
    "--job-bookmark-option" = "job-bookmark-enable"
  }

  glue_version = "2.0"
 
  max_retries  = 3
  timeout      = 60

  worker_type = "Standard"
  number_of_workers = 10
}

resource "aws_kms_key" "my_key" {
  description             = "This key is used to encrypt my sensitive data"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  policy                  = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}

data "aws_caller_identity" "current" {}


resource "aws_lb" "leolb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_alb.id]
  subnets            = [aws_subnet.custom_public_subnet2.id, aws_subnet.custom_public_subnet1.id]

  enable_deletion_protection = false

  tags = {
    Name = "example-lb"
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cstomVPC.id
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.leolb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}



resource "aws_launch_template" "example" {
  name_prefix   = "example-lt-"
  image_id      = var.amiID
  instance_type = var.instance_type
  
  // Other configurations...
}

resource "aws_autoscaling_group" "example" {
  name_prefix          = "example-asg-"
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.custom_public_subnet2.id, aws_subnet.custom_public_subnet1.id]
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  // Define scaling policies and CloudWatch alarms...
}



