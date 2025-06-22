terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "/home/yury/key.json" 
  cloud_id                 = "b1ge6ksn8gkr97asu03a"
  folder_id                = "b1gsn46kdu9vi56ievnv"
  zone      = "ru-central1-b"
}

resource "yandex_compute_instance_group" "ig-1" {
  name               = "fixed-ig-with-balancer"
  folder_id          = "b1gsn46kdu9vi56ievnv"
  service_account_id = "ajelh6a1modvi65ej1ck"
  instance_template {
    platform_id = "standard-v3"
    resources {
      core_fraction = 50
      cores  = 2
      memory = 4
    }
    boot_disk {
      initialize_params {
        image_id = "fd8ps4vdhf5hhuj8obp2"
        size = 20
      }
    }
    network_interface {
      network_id = "${yandex_vpc_network.network-2.id}"
      subnet_ids = ["${yandex_vpc_subnet.subnet-1.id}"]
      nat       = true
    }
    
    metadata = {
      user-data = "${file("/home/yury/HW/Fail-safety/Cloud-backup/files/metadata.yaml")}"
    }
    
    scheduling_policy {
      preemptible = true
    }
  }
  scale_policy {
    fixed_scale {
      size = 2
    }
  }
  allocation_policy {
    zones = ["ru-central1-b"]
  }
  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }
  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}

resource "yandex_vpc_network" "network-2" {
  name = "network2"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-2.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "network-load-balancer-1"

  listener {
    name = "network-load-balancer-1-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

output "external_ip_addresses" {
  value = yandex_compute_instance_group.ig-1.instances.*.network_interface.0.nat_ip_address
  # value = [
  #   for instance_template in yandex_compute_instance_group.ig-1.instance_template :
  #   instance_template.network_interface.0.nat_ip_address
  # ]
}

output "external_ip_address_lb" {
  value = [
    for listener in yandex_lb_network_load_balancer.lb-1.listener :
    listener.external_address_spec
  ]
}