# terraform-temporal-private-link

Automating the setup of [Temporal Cloud and Private Link](https://docs.temporal.io/cloud/security/aws-privatelink) with Terraform.

Make a copy of `terraform.tfvars.example` called `terraform.tfvars` and update the values, then:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

You will receive output that looks like the below, with instructions for validating the connection.

```bash
ec2_connection_info = <<EOT
Store the generated key locally:

	terraform output -raw private_key > neil-temporal-cloud-privatelink-key.pem
	chmod 655 neil-temporal-cloud-privatelink-key.pem

Connect to EC2 instance:

	ssh -i neil-temporal-cloud-privatelink-key.pem ec2-user@54.189.180.231

Copy Temporal Cloud credentials. In a new terminal, run:

	scp -i neil-temporal-cloud-privatelink-key.pem /path/to/cert.pem ec2-user@54.189.180.231:~
	scp -i neil-temporal-cloud-privatelink-key.pem /path/to/key.key ec2-user@54.189.180.231:~

Test connectivity:
In the SSH session to your EC2 instance, run:
	curl -vvv --http2 --cert client.pem --key client.key --connect-to ::vpce-0a5df64ffcbef2848-n2ptp3lk.vpce-svc-0f44b3d7302816b94.us-west-2.vpce.amazonaws.com:7233 https://neil-dahlke-dev.sdvdw.tmprl.cloud:7233

Note: Replace client.pem and client.key with the actual names of your mTLS certificate files.
EOT
```