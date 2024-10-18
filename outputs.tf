output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "subnet_id" {
  value       = aws_subnet.privatelink_subnet.id
  description = "The ID of the subnet"
}

output "vpc_endpoint_dns_names" {
  value       = aws_vpc_endpoint.temporal_cloud.dns_entry
  description = "The DNS entries for the VPC Endpoint"
}

output "ec2_instance_id" {
  value       = aws_instance.privatelink_test.id
  description = "The ID of the EC2 instance"
}

output "ec2_instance_public_ip" {
  value       = aws_instance.privatelink_test.public_ip
  description = "The public IP of the EC2 instance"
}

# Output the private key (Be cautious with this in production environments)
output "private_key" {
  value     = tls_private_key.privatelink_key.private_key_pem
  sensitive = true
}

# Output for EC2 connection and PrivateLink testing
output "ec2_connection_info" {
  value = <<EOT
Store the generated key locally:
	terraform output -raw private_key > ${aws_key_pair.privatelink_key.key_name}.pem
	chmod 400 ${aws_key_pair.privatelink_key.key_name}.pem

Connect to EC2 instance:
	ssh -i ${aws_key_pair.privatelink_key.key_name}.pem ec2-user@${aws_instance.privatelink_test.public_ip}

Copy Temporal Cloud credentials:
	In a new terminal, run:
	scp -i ${aws_key_pair.privatelink_key.key_name}.pem /path/to/cert.pem ec2-user@${aws_instance.privatelink_test.public_ip}:~
	scp -i ${aws_key_pair.privatelink_key.key_name}.pem /path/to/key.key ec2-user@${aws_instance.privatelink_test.public_ip}:~

Test connectivity:
In the SSH session to your EC2 instance, run:
	curl -vvv --http2 --cert "client.pem" --key "client.key" --connect-to ::${aws_vpc_endpoint.temporal_cloud.dns_entry[0]["dns_name"]}:7233 https://${var.namespace_id}.${var.account_id}.tmprl.cloud:7233

Note: Replace client.pem and client.key with the actual names of your mTLS certificate files.

If successful, the end of the command line output should read something like:
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
< HTTP/2 415
< content-type: application/grpc
< grpc-status: 3
< grpc-message: invalid gRPC request content-type ""
< date: Fri, 08 Mar 2024 20:50:39 GMT
< server: temporal
<
* Connection #0 to host ${aws_vpc_endpoint.temporal_cloud.dns_entry[0]["dns_name"]} left intact
EOT
}
