terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.12.0"
     #source = "terraform-providers/bigip"
    }
  }
}

#data "terraform_remote_state" "f5_setup" {
#  backend = "remote"
#  config = {
#    organization = "jpapazian-org"
#    workspaces = {
#      name = "F5-NIA-TFCB"
#        }
#   }
#}
 
#locals {
# address = data.terraform_remote_state.f5_setup.outputs.F5_UI
# port = "8443"
# username = "admin"
# password = data.terraform_remote_state.f5_setup.outputs.F5_Password
# }

provider "bigip" {
  address  = "https://${var.address}:${var.port}"
  username = "${var.username}"
  password = "${var.password}"
}

# generate zip file

data "archive_file" "template_zip" {
  type        = "zip"
  source_file = "ConsulWebinar.yaml"
  output_path = "ConsulWebinar.zip"
}

# deploy fast template

resource "bigip_fast_template" "consul-webinar" {
  name = "ConsulWebinar"
  source = "ConsulWebinar.zip"
  md5_hash = filemd5("ConsulWebinar.zip")
  depends_on = [data.archive_file.template_zip]
}

resource "time_sleep" "wait_1_mn" {
  depends_on = [bigip_fast_template.consul-webinar]

  create_duration = "60s"
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
  #depends_on = [bigip_fast_template.consul-webinar]
  depends_on = [time_sleep.wait_1_mn]
}
