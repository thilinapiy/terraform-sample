data "aws_ssm_parameter" "ami" {
  name = "/aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    aws_region = var.region
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "nginx"
  description = "Security group for Nginx EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp", "http-8080-tcp"]
  egress_rules        = ["all-all"]
}

module "nginx" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "nginx"
  instance_count = 1

  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [module.security_group.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  user_data                   = data.template_file.user_data.rendered
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  tags = {
    Terraform = "true"
    Name      = "nginx"
  }
}

