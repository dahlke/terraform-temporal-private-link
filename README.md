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
```

If successful, the end of the command line output should read something like:

```bash
d0.vpce-svc-0f44b3d7302816b94.us-west-2.vpce.amazonaws.com:7233 https://neil-dahlke-dev.sdvdw.tmprl.cloud:7233
* Connecting to hostname: vpce-09650138e7b166bf2-dl3b9rd0.vpce-svc-0f44b3d7302816b94.us-west-2.vpce.amazonaws.com
* Connecting to port: 7233
*   Trying 10.0.1.212:7233...
* Connected to vpce-09650138e7b166bf2-dl3b9rd0.vpce-svc-0f44b3d7302816b94.us-west-2.vpce.amazonaws.com (10.0.1.212) port 7233
* ALPN: curl offers h2,http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
*  CApath: none
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Request CERT (13):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS handshake, CERT verify (15):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=*.sdvdw.tmprl.cloud
*  start date: Sep 29 13:14:13 2024 GMT
*  expire date: Dec 28 13:14:12 2024 GMT
*  subjectAltName: host "neil-dahlke-dev.sdvdw.tmprl.cloud" matched cert's "*.sdvdw.tmprl.cloud"
*  issuer: C=US; O=Let's Encrypt; CN=R10
*  SSL certificate verify ok.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://neil-dahlke-dev.sdvdw.tmprl.cloud:7233/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: neil-dahlke-dev.sdvdw.tmprl.cloud:7233]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.3.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: neil-dahlke-dev.sdvdw.tmprl.cloud:7233
> User-Agent: curl/8.3.0
> Accept: */*
>
< HTTP/2 415
< content-type: application/grpc
< grpc-status: 3
< grpc-message: invalid gRPC request content-type ""
< date: Fri, 25 Oct 2024 16:16:39 GMT
< server: temporal
<
* Connection #0 to host vpce-09650138e7b166bf2-dl3b9rd0.vpce-svc-0f44b3d7302816b94.us-west-2.vpce.amazonaws.com left intact
EOT
```
