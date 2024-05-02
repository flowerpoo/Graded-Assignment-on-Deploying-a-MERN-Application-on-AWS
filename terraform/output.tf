output "frontend_ip" {
  value = aws_instance.webapplication.public_ip
}

output "backend_ip" {
  value = aws_instance.databaseapplication.public_ip
}