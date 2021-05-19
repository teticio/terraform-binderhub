terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.region
}

resource "aws_security_group" "binderhub" {
  name        = "binderhub"
  description = "Open ports for Binderhub and Jupyerhub"
 
  ingress {
    description = "Jupyterhub port"
    from_port   = var.jupyterhub_port
    to_port     = var.jupyterhub_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Binderhub port"
    from_port   = 80
    to_port     = 80
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
    Name = "binderhub"
  }
}

resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.binderhub.id]
 
  tags = {
    Name = "${var.tag}"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.volume_size
  }

  key_name = var.key_name

  connection {
    user        = "ubuntu"
    private_key = file("${var.key_path}")
    host        = aws_instance.ec2.public_ip
  }

  provisioner "file" {
    source      = "files/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "export JUPYTERHUB_PORT=${var.jupyterhub_port}",
      "export DOCKERHUB_USERNAME=${var.dockerhub_username}",
      "export DOCKERHUB_PASSWORD=${var.dockerhub_password}",
      "export BINDERHUB_IMAGE_PREFIX=${var.dockerhub_username}/binder-dev-",
      "export BINDERHUB_HELM_VERSION=${var.binderhub_helm_version}",
      "export EC2_PUBLIC_IP=${aws_instance.ec2.public_ip}",
      "chmod +x /tmp/bootstrap.sh",
      "/tmp/bootstrap.sh"
    ]
  }

}
