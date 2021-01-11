output "load_balancer_dns" {
  value = aws_lb.nlb.dns_name
}

output "server_a_public_ip" {
  value = aws_instance.server_a.public_ip
}

output "server_b_public_ip" {
  value = aws_instance.server_b.public_ip
}
