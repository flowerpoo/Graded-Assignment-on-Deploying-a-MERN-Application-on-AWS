# Graded-Assignment-on-Deploying-a-MERN-Application-on-AWS
Tasks:

Part 1: Infrastructure Setup with Terraform

1. AWS Setup and Terraform Initialization:

   - Configure AWS CLI and authenticate with your AWS account.

   - Initialize a new Terraform project targeting AWS.

2. VPC and Network Configuration:

   - Create an AWS VPC with two subnets: one public and one private.

   - Set up an Internet Gateway and a NAT Gateway.

   - Configure route tables for both subnets.

3. EC2 Instance Provisioning:

   - Launch two EC2 instances: one in the public subnet (for the web server) and another in the private subnet (for the database).

   - Ensure both instances are accessible via SSH (public instance only accessible from your IP).

4. Security Groups and IAM Roles:

   - Create necessary security groups for web and database servers.

   - Set up IAM roles for EC2 instances with required permissions.

5. Resource Output:

   - Output the public IP of the web server EC2 instance.

# Solution:
# 1.AWS Setup and Terraform Initialization:
* Install AWS CLI in your machine, Go to aws account create a user with access keys run the bellow command to configure your account.
```
aws configure
```
* Enter the Access key, Secrete Access key, AWS Region, Json.
* Create a folder terraform contains all the terraform file.
* Create main.tf 
```
provider "aws" {
    region = "ap-south-1"
  
}
```
* Commands used to run terraform
```
terraform init // To initialize terraform project
terraform plan // To  plan number of resources that are need to add 
terraform apply // To run the terraform file 
```
# 2.VPC and Network Configuration:

* created vpc with subnets private and public.
* values are stored in variable.tf file.
* Go through main.tf file there vpc creation and subnet creation are mentioned detailed.
* Elastic IP to associate with NAT gateway and also defined NAT gateway
* Then route tables are defined to route the traffic gateways.
* Attached the route table with public and private subnets.

# 4.Security Groups and IAM Roles:

* Security group was created with ingress and egress rukes.
* web_sg for frontend security group.
* database_sg for backend database security group.
* Define IAM role for EC2 instances an also added permission policy to the roles,
* Later that roles are attached the EC2 instance which we are going to launch.

# 3. EC2 Instance Provisioning:

* Two EC2 instance are launched the values are updated in variable.tf file.
* Subner_id, Security group, key name, IAM role all are attached to the instance while creating.

# 5. Resource Output:

* Public IP addresss of the instance we are created are available in output.tf file.

Note: All the images are stored in pics folder.
-----------------------------------------------
Part 2: Configuration and Deployment with Ansible


1. Ansible Configuration:

   - Configure Ansible to communicate with the AWS EC2 instances.

2. Web Server Setup:

   - Write an Ansible playbook to install Node.js and NPM on the web server.

   - Clone the MERN application repository and install dependencies.

3. Database Server Setup:

   - Install and configure MongoDB on the database server using Ansible.

   - Secure the MongoDB instance and create necessary users and databases.

4. Application Deployment:

   - Configure environment variables and start the Node.js application.

   - Ensure the React frontend communicates with the Express backend.

5. Security Hardening:

   - Harden the security by configuring firewalls and security groups.

   - Implement additional security measures as needed (e.g., SSH key pairs, disabling root login).

# Solution:

* Launch a EC2 instance with ubuntu OS, using key pair ssh into your local machine.
* commands to instance Ansible in your machine
```
sudo apt-get update -y
sudo apt install ansible  -y
``` 
* Inventory file that helps to store instance details need to configure, that can be configured automatically using terraform while the instance are created.
```
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
```
* Repeate the steps once more for the backend instance.
* Now copy the inventory file from terraform folder to ansible folder where exactly the inventory file is present.
```
resource "null_resource" "loCAL03" {
    triggers = {
      mytest=timestamp()
    }
    provisioner "local-exec" {
        command = "sudo cp inventory /home/ubuntu/ansible/inventory"
     }
     depends_on = [ null_resource.local01,null_resource.local02 ]
}
```
* Inventory file is ready not configure the plaubook for frontend as well as backend.
* Both frontend and backend files are docarized and try to run the docker container in the instance seperately.
* provision_frontend.yaml is the playbook file for frontend instance which try to install docker and node modules in the instance first.
* And then try to run docker container which is already pushed into doecker hub.
* output can be visible in port 3000
```
http:frontend_public_ip:3000
```
* Provision_backend.yaml is the playbook for backend instance.
* Application run in port 3001
```
http:backend_public_ip:3001
```

# Run absible playbook

Below are the commands used to both frontend and backend ansible playbook.
```
ansible-playbook -i inventory provision_frontend.yaml
ansible-playbook -i inventory provision_backend.yaml
```
Note: All the output images are stored in pics folder.

Happy Learning!!!!