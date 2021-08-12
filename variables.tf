variable "region" {
  description = "This is the AWS region. It must be provided"
}

variable "access_key" {
  description = "This is the AWS access key. It must be provided"
}

variable "secret_key" {
  description = "This is the AWS secret key. It must be provided"
}

variable "ssh_key_name" {
  description = "EC2 key-pair name. It must be provided"
}
