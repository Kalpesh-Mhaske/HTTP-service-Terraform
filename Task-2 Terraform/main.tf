provider "aws" {
  region = "ap-south-1"  # Adjust to your preferred region
}

resource "aws_security_group" "http_sg" {
  name_prefix = "http_sg"
  description = "Allow HTTP and HTTPS traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "http_service" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (verify the latest version)
  instance_type = "t2.micro"
  key_name      = "kalpesh" # Replace with your key pair

  security_groups = [aws_security_group.http_sg.name]

  user_data = file("ec2_setup.sh")

  tags = {
    Name = "HTTP Service Instance"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-for-http-service"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "MyBucket"
    Environment = "Dev"
  }
}

output "instance_public_ip" {
  value = aws_instance.http_service.public_ip
}
