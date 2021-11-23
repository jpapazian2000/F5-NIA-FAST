terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.11.1"
    }
  }
}

data "terraform_remote_state" "f5_setup" {
  backend = "remote"
  config = {
    organization = "jpapazian-org"
    workspaces = {
      name = "F5-NIA-TFCB"
        }
   }
}
 
locals {
 address = data.terraform_remote_state.f5_setup.outputs.F5_UI
 port = "8443"
 username = "admin"
 password = data.terraform_remote_state.f5_setup.outputs.F5_Password
 }

provider "bigip" {
  address  = "https://local.address:local.port"
  username = local.username
  password = local.password
}

# generate zip file

data "archive_file" "template_zip" {
  type        = "zip"
  source_file = "ConsulWebinar.yaml"
  output_path = "ConsulWebinar.zip"
}

# deploy fast template

resource "bigip_fast_template" "consul-webinar2" {
  name = "ConsulWebinar"
  source = "ConsulWebinar.zip"
  md5_hash = filemd5("ConsulWebinar.zip")
  depends_on = [data.archive_file.template_zip]
}

resource "bigip_fast_application" "nginx-webserver" {
  template        = "ConsulWebinar/ConsulWebinar"
  fast_json   = <<EOF
{
      "tenant": "Consul_SD",
      "app": "Nginx",
      "virtualAddress": "10.0.0.200",
      "virtualPort": 8080
}
EOF
  depends_on = [bigip_fast_template.consul-webinari2]
}
