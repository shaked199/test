provider "aws" {
  region = "il-central-1"
}

variable "vpc_id" {
  default = "vpc-042cee0fdc6a5a7e2" # <-- the vpc id we worked on the imtech aws 
}

variable "private_subnet_id" {
  default = ["subnet-01e6348062924d048",
    "subnet-0a1cbd99dd27a5307",
    "subnet-0d0b0b1b77639731b",
    "subnet-088b7d937a4cd5d85"]# <-- the subnets id we worked on the imtech aws 
}

variable "ssh_key_name" {
  default = "my-key" # <-- replace with your key pair name
}


resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow SSH and MySQL"
  vpc_id      = var.vpc_id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

 
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"        
    cidr_blocks = ["0.0.0.0/0"]   
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-0241b2b622c018ede"
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_id
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "shakedinstence"
  }
}


resource "aws_db_subnet_group" "default" {
  name       = "my-db-subnet-group"
  subnet_ids = [var.private_subnet_id] 

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_db_instance" "mysql" {
  identifier             = "my-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "aA123456"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "My RDS DB"
  }
}
