provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_security_group" "web_sg" {
  name        = "security group for web server "
  description = "security group for web server"
 

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

  // Define ingress rules (inbound traffic)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPv4 addresses (open to the world)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]  # Allow SSH access only from a specific CIDR block
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

# Define EC2 instance
resource "aws_instance" "webapplication" {
  ami  = var.ami
  instance_type = var.instance_type
  key_name = "flo1"
  tags = {
    Name = "webapplication"
  }
  
}

resource "aws_instance" "databaseapplication" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name         = "flo1"
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