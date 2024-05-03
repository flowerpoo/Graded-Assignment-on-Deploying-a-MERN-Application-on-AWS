provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = var.public_subnet_cidr

    tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = var.private_subnet_cidr

    tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
    Name = "main"
  }
  
}

resource "aws_eip" "eip" {
    domain = "vpc"
  
}

resource "aws_nat_gateway" "gw_NAT" {
    allocation_id = aws_eip.eip.id
    subnet_id     = aws_subnet.private_subnet.id

    tags = {
        Name = "gw_NAT"
    }
  
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.main_vpc.id

    route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
    Name = "public_route"
    }
  
}

resource "aws_route_table" "private_route" {
    vpc_id = aws_vpc.main_vpc.id

    route {
    cidr_block = "10.0.2.0/24"
    gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
    Name = "public_route"
    }
  
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_security_group" "web_sg" {
  name        = "security group for web server "
  description = "security group for web server"
  vpc_id = aws_vpc.main_vpc.id

  // Define ingress rules (inbound traffic)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]  # Allow SSH access only from a specific CIDR block
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }

  // Define egress rules (outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic to anywhere
  }

   tags = {
    Name = "web__SG"
  }
}

resource "aws_security_group" "database_sg" {
  name        = "security group for database "
  description = "security group for database"
  vpc_id = aws_vpc.main_vpc.id

  // Define ingress rules (inbound traffic)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]  # Allow SSH access only from a specific CIDR block
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }

  // Define egress rules (outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic to anywhere
  }

   tags = {
    Name = "database__SG"
  }
}

resource "aws_iam_policy" "ec2_permissions_policy" {
  name        = "EC2PermissionsPolicy"
  description = "Policy granting necessary permissions for EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Define IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name               = "EC2InstanceRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_permissions_policy.arn
}

# Define EC2 instance
resource "aws_instance" "webapplication" {
  ami  = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  key_name = "flo1"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    Name = "webapplication"
  }
  
}

resource "aws_instance" "databaseapplication" {
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.private_subnet.id
  key_name         = "flo1"
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  tags = {
    Name = "databaseapplication"
  }
  
}

resource "null_resource" "local01" {
    triggers = {
      mytest=timestamp()
    }

    provisioner "local-exec" {
        command = <<EOF
        echo "[frontend]" >> inventory
        "echo ${aws_instance.webapplication.tags.Name} ansible_host=${aws_instance.webapplication.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/terraform/flo1.pem >> inventory"
        EOF
      
    }

    depends_on = [ aws_instance.webapplication ]
  
}

resource "null_resource" "local02" {
    triggers = {
      mytest=timestamp()
    }

    provisioner "local-exec" {
        command =<<EOF
          echo "[backend]" >> inventory
         "echo ${aws_instance.databaseapplication.tags.Name} ansible_host=${aws_instance.databaseapplication.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/terraform/flo1.pem >> inventory"
          EOF
      
    }

    depends_on = [ aws_instance.databaseapplication ]
  
}

resource "null_resource" "loCAL03" {
    triggers = {
      mytest=timestamp()
    }
    provisioner "local-exec" {
        command = "sudo cp inventory /home/ubuntu/ansible/inventory"
         
      
    }

    depends_on = [ null_resource.local01,null_resource.local02 ]
  
}