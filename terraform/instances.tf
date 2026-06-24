resource "aws_instance" "ansible_controller" {
  region                 = var.region
  availability_zone      = var.availability_zone
  ami                    = var.amiID["controller"]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.controller_sg.id]
  key_name               = "control-key"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/controlkey")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "scripts/setup_controller.sh"
    destination = "/tmp/setup_controller.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_controller.sh",
      "sudo /tmp/setup_controller.sh"
    ]
  }

  tags = {
    Name = "controller"
  }
}

resource "aws_instance" "web_server1" {
  region                 = var.region
  availability_zone      = var.availability_zone
  ami                    = var.amiID["web"]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "web-key"

  tags = {
    Name = "web01"
  }
}

resource "aws_instance" "web_server2" {
  region                 = var.region
  availability_zone      = var.availability_zone
  ami                    = var.amiID["web"]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "web-key"

  tags = {
    Name = "web02"
  }
}

resource "aws_instance" "web_server3" {
  region                 = var.region
  availability_zone      = var.availability_zone
  ami                    = var.amiID["controller"]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "web-key"

  tags = {
    Name = "web03"
  }
}

resource "aws_instance" "db_server" {
  region                 = var.region
  availability_zone      = var.availability_zone
  ami                    = var.amiID["db"]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = "db-key"

  tags = {
    Name = "db"
  }
}