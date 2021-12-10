
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


######################################
# 5. Create VPC vpc_wp_admin         #
######################################

resource "aws_vpc" "vpc_wp_admin" {
  #cidr_block = var.cidr-block-admin
  cidr_block = "10.0.0.0/16"
  enable_dns_support = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink = "false"
  instance_tenancy = "default"    

  tags = {
    name = var.env 
  }

}

# 5.3. Create Subnet

resource "aws_subnet" "subnet_wp_admin_public" {
  vpc_id = aws_vpc.vpc_wp_admin.id
  #cidr_block = var.cidr-block-subnet-admin
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  
  tags = {
    name = var.subnet_wp_admin 
  }
}


resource "aws_subnet" "subnet_wp_admin_private" {
  vpc_id = aws_vpc.vpc_wp_admin.id
  #cidr_block = var.cidr-block-subnet-admin
  cidr_block = "10.0.2.0/24"
  
  tags = {
    name = var.subnet_wp_admin 
  }
}



# 5.1.Create wp_web_gw in the VPC vpc_wp_web
resource "aws_internet_gateway" "inet_gw_wp_admin" {
  vpc_id = aws_vpc.vpc_wp_admin.id

  tags = {
    Name = "wp_admin_gw"
  }
}
# 5.2.Add a Routing Table into the vpc_wp_web
resource "aws_route_table" "route_table_wp_admin" {
  vpc_id = aws_vpc.vpc_wp_admin.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gw_wp_admin.id
  }

  tags = {
    Name = "route_table_wp_admin"
  }
}


# 5.4. Associate Route Tabl with Subnet
resource "aws_route_table_association" "rt_aso_sb_wp_admin" {
  subnet_id      = aws_subnet.subnet_wp_admin_public.id
  route_table_id = aws_route_table.route_table_wp_admin.id
}

resource "aws_security_group" "sg_admin_public" {
   name        = "allow_admin_traffic"
   description = "Allow admin inbound traffic"
   vpc_id      = aws_vpc.vpc_wp_admin.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 8080
     to_port     = 8080
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 9000
     to_port     = 9000
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 9001
     to_port     = 9001
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
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
     Name = "allow_admin"
   }
 }

 #5.5. Create a network interface with an ip in the subnet that was created in step 4

 resource "aws_network_interface" "admin-server-nic" {
   subnet_id       = aws_subnet.subnet_wp_admin_public.id
   private_ips     = ["10.0.1.50"]
   security_groups = [aws_security_group.sg_admin_public.id]

 }
 
  #5.7. Create Ubuntu server and install/enable apache2

 resource "aws_instance" "jenkins-sonar-server-instance" {
   ami               = "ami-002068ed284fb165b"
   instance_type     = "t3.medium"
   key_name         = "jenkins-sonar-keypair"
   #security_groups = [aws_security_group.sg_admin_public.id]

   network_interface {
     device_index         = 0
     network_interface_id = aws_network_interface.admin-server-nic.id
   }

   user_data = <<-EOF
                 !/bin/bash
                 sudo amazon-linux-extras install java-openjdk11 -y
                 sudo yum install postgresql postgresql-server -y
                 sudo -u postgres psql -c "CREATE USER sonar WITH PASSWORD 'sonar';"
                 sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"                 
                 sudo yum install unzip
                 sysctl -w vm.max_map_count=262144
                 cd $HOME
                 wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.2.1.49989.zip
                 unzip sonarqube-9.2.1.49989.zip
                 cd /home/ec2-user/sonarqube-9.2.1.49989/conf/
                 cp sonar.properties sonar_org.properties
                 echo -e "sonar.jdbc.username=sonar\nsonar.jdbc.password=sonar\nsonar.jdbc.url=jdbc:postgresql://localhost/sonarqube" >> sonar.properties
                 cd /home/ec2-user/sonarqube-9.2.1.49989/bin/linux-x86-64                 
                 sh sonar.sh start
                 wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.55/bin/apache-tomcat-9.0.55.zip
                 unzip apache-tomcat-9.0.55.zip
                 cd /home/ec2-user/apache-tomcat-9.0.55/webapps
                 wget https://get.jenkins.io/war/2.323/jenkins.war
                 cd /home/ec2-user/apache-tomcat-9.0.55/bin
                 sh startup.sh
                 EOF
   tags = {
     Name = "jenkins-sonar-server-instance"
   }
 }

#5.6. Assign an elastic IP to the network interface created in step 7

 resource "aws_eip" "eip_admin" {
   vpc                       = true
   #network_interface         = aws_network_interface.admin-server-nic.id
   associate_with_private_ip = "10.0.1.50"
   depends_on                = [aws_internet_gateway.inet_gw_wp_admin]
   instance     = aws_instance.jenkins-sonar-server-instance.id
 }

 output "admin_server_public_ip" {
   value = aws_eip.eip_admin.public_ip
 }



 output "server_private_ip" {
   value = aws_instance.jenkins-sonar-server-instance.private_ip

 }

 output "server_id" {
   value = aws_instance.jenkins-sonar-server-instance.id
 }


resource "aws_db_instance" "default" {
# Allocating the storage for database instance.
  allocated_storage    = 10
# Declaring the database engine and engine_version
  engine               = var.engine
  engine_version       = var.engine_version
# Declaring the instance class
  instance_class       = var.instance_class
  name                 = var.name
# User to connect the database instance 
  username             = var.username
# Password to connect the database instance 
  password             = var.password
  parameter_group_name = var.parameter_group_name
}