variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

variable "dcos_aws_region" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "us-west-2"
}

data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {
  region = "us-west-2"
}

module "dcos" {

  providers = {
    aws = "aws"
  }
  source = "dcos-terraform/dcos/aws"
  version = "~> 0.1.0"
  availability_zones = ["us-west-2a","us-west-2b","us-west-2c"]

  dcos_instance_os    = "centos_7.5"
  cluster_name        = "pangeo-lab"
  ssh_public_key_file = "<insert path to your key>"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  private_agents_instance_type = "m4.4xlarge"
  private_agents_extra_volumes = [
   {
    size = "20"
    type = "gp2"
    iops = "5000"
    device_name = "/dev/xvde"
   }
  ]

  num_masters        = "3"
  num_private_agents = "6"
  num_public_agents  = "2"
  public_agents_additional_ports = ["6443"]

  dcos_version = "1.12.2"
  dcos_security = "permissive"
  dcos_variant  = "open"

  dcos_install_mode = "${var.dcos_install_mode}"
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}
