# serverless-static-site-aws
 Infrastructure for a static website on AWS using S3, CloudFront, Lambda, and DynamoDB. This project sets up a serverless architecture for hosting static content with global distribution and integration with a backend API for dynamic operations.

This project consists of receiving information about student registration and queries through the front end, through a static website with HTML and Java Script. The Java Script triggers the API Gateway with the POST/GET method, triggering the Lambda that will query/include the student in Dynamodb. 
The resources used were: CloudFront, S3, API Gateway, Lambda and Dynamodb.
The infrastructure was provisioned using Terraform.

**_NOTE:_** A daily quota of 20 requests was added to the API Gateway. To change the value, you need to change the variable:
  ```bash
variable "limit_quota" {
  type    = number
  default = 20
}
  ```

## Prerequisites
[Installing the AWS CLI](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/getting-started-install.html)
  ```bash
  aws --version
  ```

## Configure AWS Access
[Configure your AWS credentials](https://docs.aws.amazon.com/pt_br/cli/v1/userguide/cli-configure-files.html)
  ```bash
  aws configure
  ```

Validate aws access with an example to get the account_id
  ```bash
  aws sts get-caller-identity 
  ```

### Terraform

```bash
cd terraform # Access the folder terraform

terraform init # Initialize Terraform

terraform plan # To check the resources that will be created
terraform plan -no-color > tfplan.txt # Save plan in a file

terraform apply -auto-approve # Apply settings

terraform destroy -auto-approve # Do the destroy
   ```

For more details, see the documentation:
- [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/home.html) 
- [Terraform](https://developer.hashicorp.com/terraform/docs)
