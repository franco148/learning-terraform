data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}

module "tf_vpc_module" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf_learning_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "tf_learning" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  # vpc_security_group_ids = [ aws_security_group.tf_learning_sg.id ] // Before security group
  vpc_security_group_ids = [ module.tf-security-group-module.security_group_id ]

  subnet_id = module.tf_vpc_module.public_subnets[0]

  tags = {
    Name = "learning-terraform"
  }
}

module "tf-security-group-module" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  name    = "tf_learning_sg_2"

  # vpc_id  = data.aws_vpc.default.id // Before vpc module
  vpc_id = module.tf_vpc_module.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

# resource "aws_security_group" "tf_learning_sg" {
#   name        = "tf_learning_sg"
#   description = "Allow http and https in. Allow everything out"

#   tags = {
#     Terraform = "true"
#   }

#   vpc_id = data.aws_vpc.default.id
# }

# resource "aws_security_group_rule" "tf_learning_sg_rule_http_in" {
#   type        = "ingress"
#   from_port   = 80
#   to_port     = 80
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]

#   security_group_id = aws_security_group.tf_learning_sg.id
# }


# resource "aws_security_group_rule" "tf_learning_sg_rule_https_in" {
#   type        = "ingress"
#   from_port   = 443
#   to_port     = 443
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]

#   security_group_id = aws_security_group.tf_learning_sg.id
# }


# resource "aws_security_group_rule" "tf_learning_sg_rule_everything_out" {
#   type        = "egress"
#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.tf_learning_sg.id
# }
