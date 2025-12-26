terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  access_key = ""
  secret_key = ""
  project_id = var.project_id
  region     = ""
  zone       = ""
}


# add a resource for the security group that allows https and ssh from specific ips

resource "scaleway_instance_ip" "asa_server_ipv6" {
  type       = routed_ipv6
  zone       = var.zone
  project_id = var.project_id
}

resource "scaleway_instance_server" "asa_nginx_cert_demo" {
  type              = "DEV1-S"
  image             = "ubuntu_jammy"
  name              = "asa_nginx_cert_demo"
  tags              = ["demo", "web"]
  ip_id             = scaleway_instance_ip.asa_server_ipv6
  security_group_id = to_edit #to edit
  enable_dynamic_ip = false
  state             = "started"
}
