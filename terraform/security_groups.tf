resource "aws_security_group" "controller_sg" {
  name        = "controller-sg"
  description = "Security group for the ansible controller instance."

  tags = {
    Name = "controller-sg"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for the web servers."

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for the database server."

  tags = {
    Name = "db-sg"
  }
}

# ================= INGRESS RULES ======================

resource "aws_vpc_security_group_ingress_rule" "myip_ssh_controller" {
  security_group_id = aws_security_group.controller_sg.id
  cidr_ipv4         = "${chomp(data.http.my_public_ip.response_body)}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "myip_ssh_web" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "${chomp(data.http.my_public_ip.response_body)}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "myip_ssh_db" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "${chomp(data.http.my_public_ip.response_body)}/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "controller_ssh_web" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.controller_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "controller_ssh_db" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.controller_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_http_web" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_http_db" {
#   security_group_id = aws_security_group.db_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "tcp"
#   from_port         = 80
#   to_port           = 80
# }

# ================= EGRESS RULES ======================

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_controller" {
  security_group_id = aws_security_group.controller_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_controller" {
  security_group_id = aws_security_group.controller_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_web" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_web" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_db" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_db" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}