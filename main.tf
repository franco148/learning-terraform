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

module "tf_vpc_module" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf-learning-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "tf_autoscaling_module" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.4.1"
  
  name     = "tf-learning"
  min_size = 1
  max_size = 2

  vpc_zone_identifier = module.tf_vpc_module.public_subnets
  target_group_arns   = [module.tf_alb_module.security_group_arn]
  security_groups     = [module.tf-security-group-module.security_group_id]

  image_id      = data.aws_ami.app_ami.id
  instance_type = var.instance_type
}


module "tf_alb_module" {
  source = "terraform-aws-modules/alb/aws"

  name    = "tf-learning-alb"
  vpc_id  = module.tf_vpc_module.vpc_id
  subnets = module.tf_vpc_module.public_subnets

  security_groups = [module.tf-security-group-module.security_group_id]

  target_groups = {
    ex-instance = {
      name_prefix      = "tf-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"      
    }
  }

  tags = {
    Environment = "dev"
    Project     = "Terraform Learning"
  }
}


module "tf-security-group-module" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"
  name    = "tf-learning-sg-2"

  # vpc_id  = data.aws_vpc.default.id // Before vpc module
  vpc_id = module.tf_vpc_module.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
