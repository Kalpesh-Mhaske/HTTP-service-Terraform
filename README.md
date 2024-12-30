# HTTP-service--Terraform
# HTTP Service to List S3 Bucket Contents

This document provides step-by-step instructions for creating an HTTP service in **PHP** to list the contents of an AWS S3 bucket. The service exposes an endpoint `GET http://IP:PORT/list-bucket-content/<path>` that returns the content of the bucket in JSON format.

## Prerequisites

1. **AWS S3 Bucket**:
   - Ensure you have access to an AWS S3 bucket.
   - Example structure for the bucket:
     ```
     |_ dir1
     |_ dir2
     |_ dir3
     |_ file1
     |_ file2
     ```

2. **EC2 Instance**:
   - Running an EC2 instance with a public IP or hostname.
   - Ensure security groups allow inbound traffic on the desired port (e.g., `8080`).

3. **IAM Role with S3 Access**:
   - Attach an IAM role to the EC2 instance with the following permissions:
     - `s3:ListBucket`
     - `s3:GetObject`

4. **Software Requirements**:
   - PHP (version 7.4 or higher)
   - Composer (dependency manager for PHP)
   - AWS SDK for PHP

---

## Installation Steps

### Step 1: Install PHP

1. Update system packages:
   ```bash
   sudo yum update -y
   ```

2. Install PHP:
   ```bash
   sudo amazon-linux-extras install php8.0 -y
   ```

3. Verify PHP installation:
   ```bash
   php -v
   ```

---

### Step 2: Install Composer

1. Download Composer:
   ```bash
   curl -sS https://getcomposer.org/installer | php
   ```

2. Move Composer to a global location:
   ```bash
   sudo mv composer.phar /usr/local/bin/composer
   ```

3. Verify Composer installation:
   ```bash
   composer --version
   ```

---

### Step 3: Install AWS SDK for PHP

1. Navigate to your project directory:
   ```bash
   mkdir my-php-app
   cd my-php-app
   ```

2. Install the AWS SDK using Composer:
   ```bash
   composer require aws/aws-sdk-php
   ```

---

### Step 4: Write the PHP Script

1. Create a new PHP file named `app.php`:
   ```bash
   nano app.php
   ```

2. Add the following code to `app.php`:

   ```php
   <?php

   // Include the Composer autoloader
   require 'vendor/autoload.php';

   use Aws\S3\S3Client;
   use Aws\Exception\AwsException;

   // Set up the S3 client
   $s3Client = new S3Client([
       'version' => 'latest',
       'region'  => 'us-east-1', // Change to your S3 region
   ]);

   $bucketName = 'your-bucket-name'; // Replace with your bucket name

   // Get the path from the URL if it exists
   $path = isset($_GET['path']) ? $_GET['path'] : '';

   // Set the response header to application/json
   header('Content-Type: application/json');

   try {
       // Define the parameters to list the objects in the bucket
       $params = [
           'Bucket' => $bucketName,
           'Prefix' => $path,
           'Delimiter' => '/',
       ];

       // Get the contents of the bucket
       $result = $s3Client->listObjectsV2($params);
       $content = [];

       // List subdirectories (CommonPrefixes)
       if (isset($result['CommonPrefixes'])) {
           foreach ($result['CommonPrefixes'] as $prefix) {
               $content[] = basename(rtrim($prefix['Prefix'], '/'));
           }
       }

       // List files (Contents)
       if (isset($result['Contents'])) {
           foreach ($result['Contents'] as $object) {
               $content[] = basename($object['Key']);
           }
       }

       // Return the content as JSON
       echo json_encode(['content' => $content]);

   } catch (AwsException $e) {
       // If there's an error, return an error message
       echo json_encode(['error' => $e->getMessage()]);
   }

   ?>
   ```

---

### Step 5: Run the PHP Server

1. Start the PHP built-in server:
   ```bash
   php -S 0.0.0.0:8080
   ```

2. Access the service:
   ```
   http://<your-ec2-ip>:8080/app.php
   ```

---

### Step 6: Test the Endpoint

1. List the top-level content of the bucket:
   ```bash
   curl http://<your-ec2-ip>:8080/list-bucket-content
   ```

   Example Response:
   ```json
   {"content": ["dir1", "dir2", "file1", "file2"]}
   ```

2. List the contents of a subdirectory:
   ```bash
   curl http://<your-ec2-ip>:8080/list-bucket-content?path=dir1
   ```

   Example Response:
   ```json
   {"content": []}
   ```

---

### Troubleshooting

- **Issue**: `ModuleNotFoundError` for AWS SDK.
  - **Solution**: Ensure AWS SDK is installed using Composer.

- **Issue**: PHP server not responding.
  - **Solution**: Check security group settings and ensure port `8080` is open.

---

### Notes

- Use a web server (e.g., Apache or Nginx) for production environments.
- Ensure your IAM role has the necessary permissions to access the S3 bucket.
- Avoid exposing sensitive credentials in your code.

# Setting Up Terraform Configuration on Amazon Linux

## Overview
This guide provides step-by-step instructions to set up Terraform on an Amazon Linux instance, configure Terraform files to provision AWS resources, and deploy the infrastructure. The configuration includes creating an EC2 instance, an S3 bucket, and necessary security groups.

---

## Prerequisites

1. **Amazon Linux instance**: Ensure you have access to an Amazon Linux instance with internet connectivity.
2. **AWS CLI**: Installed and configured on your Amazon Linux instance.
3. **Terraform**: Installed on the Amazon Linux instance.

---

## Terraform Configuration Files

### 1. `provider.tf`
This file configures the AWS provider and specifies the AWS region.

```hcl
provider "aws" {
  region = "us-west-2"  # Specify the region, e.g., us-west-2 for free-tier eligibility
}
```

### 2. `variables.tf`
Defines variables for the Terraform configuration, such as instance type, AMI ID, and S3 bucket name.

```hcl
variable "instance_type" {
  default = "t2.micro"  # Free-tier eligible instance
}

variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0"  # Free-tier eligible Amazon Linux AMI in us-west-2
}

variable "bucket_name" {
  default = "my-http-service-bucket"
}
```

### 3. `main.tf`
Defines the resources to be provisioned, including an EC2 instance, S3 bucket, and security groups.

```hcl
resource "aws_instance" "http_service_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "http-service-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo service httpd start
              sudo chkconfig httpd on
              echo "Hello from AWS EC2!" > /var/www/html/index.html
            EOF
}

resource "aws_s3_bucket" "http_service_bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_security_group" "http_service_sg" {
  name        = "http-service-sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "http_service_sg_rule" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.http_service_sg.id
}
```

### 4. `outputs.tf`
Defines outputs to display relevant information after the infrastructure is deployed.

```hcl
output "instance_public_ip" {
  value = aws_instance.http_service_instance.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.http_service_bucket.bucket
}
```

---

## Steps to Initialize and Apply Terraform Configuration

### Step 1: Initialize Terraform
Run the following command in the directory containing the configuration files:

```bash
terraform init
```
This downloads the AWS provider plugin and sets up the working directory for Terraform.

### Step 2: Plan the Deployment
Preview the changes Terraform will make:

```bash
terraform plan
```
This generates an execution plan, detailing the resources to be created.

### Step 3: Apply the Configuration
Deploy the resources:

```bash
terraform apply
```
Type `yes` when prompted to confirm the deployment.

### Step 4: Verify Outputs
Once the deployment is complete, Terraform will display the outputs defined in `outputs.tf`, such as:

- The public IP of the EC2 instance
- The name of the S3 bucket

### Step 5: Clean Up Resources
To avoid incurring charges, destroy the resources when they are no longer needed:

```bash
terraform destroy
```
Type `yes` to confirm the destruction.

---

## Notes

- Ensure your AWS CLI credentials are configured correctly using `aws configure`.
- Use free-tier eligible resources (e.g., `t2.micro` instances) to minimize costs.
- Modify the region and AMI ID in `variables.tf` to match your requirements.
- Always validate your Terraform configuration with `terraform validate` before applying changes.

---
