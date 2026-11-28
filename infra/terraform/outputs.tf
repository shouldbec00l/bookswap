output "public_ip" {
  description = "Публічна IP-адреса сервера"
  value       = aws_eip.app.public_ip
}

output "ssh_command" {
  description = "Команда для підключення по SSH"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.ansible_user}@${aws_eip.app.public_ip}"
}

output "app_url" {
  description = "URL застосунку (після розгортання проєкту)"
  value       = "http://${aws_eip.app.public_ip}"
}

output "vpc_id" {
  description = "ID створеної VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "ID групи безпеки"
  value       = aws_security_group.web.id
}
