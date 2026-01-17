output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.asa-demo-network-load-balancer.dns_name
}
