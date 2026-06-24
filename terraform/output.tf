
# ================== PUBLIC IPS ======================
output "controller_public_ip" {
  description = "Public IP of the controller instance."
  value       = aws_instance.ansible_controller.public_ip
}

output "web01_public_ip" {
  description = "Public IP of web01 server."
  value       = aws_instance.web_server1.public_ip
}

output "web02_public_ip" {
  description = "Public IP of web02 server."
  value       = aws_instance.web_server2.public_ip
}

output "web03_public_ip" {
  description = "Public IP of web03 server."
  value       = aws_instance.web_server2.public_ip
}

output "db_public_ip" {
  description = "Public IP of the DB server."
  value       = aws_instance.db_server.public_ip
}

# ================== PRIVATE IPS ======================

output "controller_private_ip" {
  description = " Private IP of the controller instance."
  value       = aws_instance.ansible_controller.private_ip
}

output "web01_private_ip" {
  description = "Private IP of web01 server."
  value       = aws_instance.web_server1.private_ip
}

output "web02_private_ip" {
  description = "Private IP of web02 server."
  value       = aws_instance.web_server2.private_ip
}

output "web03_private_ip" {
  description = "Private IP of web03 server."
  value       = aws_instance.web_server3.private_ip
}

output "db_private_ip" {
  description = "Private IP of the DB server."
  value       = aws_instance.db_server.private_ip
}