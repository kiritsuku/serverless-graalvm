# Serverless Graalvm Example Project

### Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/)
- Java 11
- Terraform
- [Maven](https://maven.apache.org/download.cgi?Preferred=ftp://ftp.osuosl.org/pub/apache/) (at least 3.8.5)

1. First build the project by running `./build-graalvm-lambda.sh`.
2. Deploy the code by executing `terraform plan -var profile=$AWS_PROFILE`
