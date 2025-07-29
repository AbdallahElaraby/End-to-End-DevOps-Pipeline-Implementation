# -----------------------------
# VPC
# -----------------------------

module "vpc" {
  source     = "./modules/vpc_mod"
  cidr_block = "10.0.0.0/16"
}

# -----------------------------
# Elastic IP
# -----------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# -----------------------------
# Key Pairs
# -----------------------------
resource "aws_key_pair" "project" {
  key_name   = "project"
  public_key = file("~/.ssh/id_rsa.pub")
}

# -----------------------------
# Amazon S3
# -----------------------------
resource "aws_s3_bucket" "mys3statebucket" {
  bucket = "my-tf-state-project-fortstack-bucket"

  tags = {
    Name        = "My bucket"
  }
}

# -----------------------------
# Amazon DynamoDB
# -----------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock-state-table"
  billing_mode = "PAY_PER_REQUEST"  
  hash_key     = "LockID"  
  attribute {
    name = "LockID"
    type = "S"
  }                    
}


# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.project_vpc-id

  tags = {
    Name = "IG"
  }
}

# -----------------------------
# NAT Gateway
# -----------------------------

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = module.pub_sub_1.puplic_subnet_id_1
  depends_on = [ aws_eip.nat_eip ]
  tags = {
    Name = "NAT GW"
  }
}

# -----------------------------
# Public Subnets
# -----------------------------

module "pub_sub_1" {
  source            = "./modules/subnet_mod_pup"
  cidr_block        = "10.0.0.0/24"
  vpc_id            = module.vpc.project_vpc-id
  Name              = "Puplic Subnet 1"
  availability_zone = "us-east-1a"
}
module "pub_sub_2" {
  source            = "./modules/subnet_mod_pup"
  cidr_block        = "10.0.2.0/24"
  vpc_id            = module.vpc.project_vpc-id
  Name              = "Puplic Subnet 2"
  availability_zone = "us-east-1b"
}


# -----------------------------
# Private Subnets
# -----------------------------
module "priv_sub_1" {
  source            = "./modules/subnet_mod_priv"
  cidr_block        = "10.0.1.0/24"
  vpc_id            = module.vpc.project_vpc-id
  Name              = "Private Subnet 1"
  availability_zone = "us-east-1a"
}

# -----------------------------
# Route Table
# -----------------------------
module "route_table" {
  source     = "./modules/route_table_mod"
  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.project_vpc-id
  Name       = "Route table 1"
  IGW        = aws_internet_gateway.gw.id
}

resource "aws_route_table" "route_tab2" {
  vpc_id =module.vpc.project_vpc-id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.gw.id
  }
  tags = {
    Name = "Route Table 2"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = module.pub_sub_1.puplic_subnet_id_1
  route_table_id = module.route_table.route_table_id
}
resource "aws_route_table_association" "b" {
  subnet_id      = module.pub_sub_2.puplic_subnet_id_1
  route_table_id = module.route_table.route_table_id
}
resource "aws_route_table_association" "c" {
  subnet_id      = module.priv_sub_1.private_subnet_id
  route_table_id = aws_route_table.route_tab2.id
}

# -----------------------------
# Security Groups
# -----------------------------
resource "aws_security_group" "frontEndTraffic" {
  name        = "Bastion Host and Proxy Web Server"
  description = "allows http and ssh on instances "
  vpc_id      = module.vpc.project_vpc-id
  tags = {
    Name = "Proxy Web Server SG"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_FE" {
  security_group_id = aws_security_group.frontEndTraffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_FE" {
  security_group_id = aws_security_group.frontEndTraffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_flask_FE" {
  security_group_id = aws_security_group.frontEndTraffic.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 5000
  ip_protocol       = "tcp"
  to_port           = 5000
}
resource "aws_vpc_security_group_egress_rule" "allow_all_egress_FE" {
  security_group_id = aws_security_group.frontEndTraffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "backEndTraffic" {
  name        = "BackEnd Web Server"
  description = "allows http and ssh on instances "
  vpc_id      = module.vpc.project_vpc-id
  tags = {
    Name = "BackEnd Web Server SG"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_BE" {
  security_group_id = aws_security_group.backEndTraffic.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_BE" {
  security_group_id = aws_security_group.backEndTraffic.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_internal_proxy" {
  security_group_id = aws_security_group.backEndTraffic.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 5000
  ip_protocol       = "tcp"
  to_port           = 5000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress_BE" {
  security_group_id = aws_security_group.backEndTraffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
# -----------------------------
# Amazon Machine Image
# -----------------------------
data "aws_ami" "amz-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}
# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "proxy" {
  ami                         = data.aws_ami.amz-ami.image_id
  instance_type               = "t2.micro"
  subnet_id                   = module.pub_sub_1.puplic_subnet_id_1
  vpc_security_group_ids      = [aws_security_group.frontEndTraffic.id]
  key_name                    = aws_key_pair.project.key_name

  tags = {
    Name = "Proxy Server"
  }


  provisioner "file" {
  source      = "~/.ssh/id_rsa"
  destination = "/home/ec2-user/.ssh/id_rsa"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa") 
    host        = self.public_ip
  }
}
provisioner "remote-exec" {
  inline = [
    "chmod 600 /home/ec2-user/.ssh/id_rsa",
    "ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub"
  ]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
  provisioner "file" {
    source      = "proxyscript.sh"
    destination = "/tmp/script.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  provisioner "file" {
    source      = "ansible"
    destination = "/tmp/ansible"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "echo Proxy Public IP: ${self.public_ip} >> all_ips.txt"
  }
}
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.amz-ami.image_id
  instance_type               = "t3.medium"
  subnet_id                   = module.priv_sub_1.private_subnet_id
  private_ip = "10.0.1.10"
  vpc_security_group_ids      = [aws_security_group.backEndTraffic.id]
  key_name                    = aws_key_pair.project.key_name

  tags = {
    Name = "Backend Server"
  }

  root_block_device {
    volume_size = 20  
    volume_type = "gp2"
  }

  provisioner "file" {
    source      = "backend-script.sh"
    destination = "/tmp/script.sh"

    connection {
      type                = "ssh"
      user                = "ec2-user"
      private_key         = file("~/.ssh/id_rsa")
      host                = self.private_ip
      bastion_host        = aws_instance.proxy.public_ip
      bastion_user        = "ec2-user"
      bastion_private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh",
      "sudo yum install -y cloud-utils-growpart",
      "sudo growpart /dev/nvme0n1 1",
      "sudo xfs_growfs /"
    ]

    connection {
      type                = "ssh"
      user                = "ec2-user"
      private_key         = file("~/.ssh/id_rsa")
      host                = self.private_ip
      bastion_host        = aws_instance.proxy.public_ip
      bastion_user        = "ec2-user"
      bastion_private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "local-exec" {
    command = "echo Backend Private IP: ${self.private_ip} >> all_ips.txt"
  }

  depends_on = [aws_instance.proxy]
}

resource "null_resource" "add_known_host" {
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${aws_instance.proxy.public_ip} >> ~/.ssh/known_hosts"
  }

  depends_on = [aws_instance.proxy]
}

resource "null_resource" "nginx_setup" {
  provisioner "file" {
    source      = "ansible-exec.sh"
    destination = "/tmp/ansible/ansible-exec.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.proxy.public_ip
      timeout     = "2m"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/ansible/ansible-exec.sh",
      "/tmp/ansible/ansible-exec.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.proxy.public_ip
      timeout     = "2m"
      agent       = false
    }
  }

  depends_on = [
    aws_instance.proxy,
    aws_instance.backend,
    null_resource.add_known_host
  ]
}

# -----------------------------
# Internet Facing Load Balancer
# -----------------------------
resource "aws_lb" "FE_LB" {
  name               = "FrontEnd-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontEndTraffic.id]
  subnets            = [module.pub_sub_1.puplic_subnet_id_1,module.pub_sub_2.puplic_subnet_id_1]
  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
  provisioner "local-exec" {
    command = "echo  LB Puplic DNS:  ${self.dns_name} >> all_ips.txt"
  }
  
}
resource "aws_lb_target_group" "FE_TG" {
  name     = "FrontEnd-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.project_vpc-id
}
resource "aws_lb_target_group_attachment" "FE_TG_ATTACH" {
  depends_on = [ aws_instance.proxy ]
  target_group_arn = aws_lb_target_group.FE_TG.arn
  target_id        = aws_instance.proxy.id
  port             = 80
}

resource "aws_lb_listener" "FE_L" {
  load_balancer_arn = aws_lb.FE_LB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.FE_TG.arn
  }
}