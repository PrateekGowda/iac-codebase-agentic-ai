terraform {
  backend "s3" {
    bucket = "hack-aib-tf-backend"
    key    = "example-workload/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
