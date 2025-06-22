terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

#variable "yandex_cloud_token" {
#  type = string
#  description = "Данная переменная потребует ввести секретный токен в консоли при запуске terraform plan/apply"
#}

#provider "yandex" {
#  token     = var.yandex_cloud_token #секретные данные должны быть в сохранности!! Никогда не выкладывайте токен в публичный доступ.
#  cloud_id  = "xxx"
#  folder_id = "xxx"
#  zone      = "ru-central1-a"
#}

provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = "b1ge6ksn8gkr97asu03a"
  folder_id                = "b1gsn46kdu9vi56ievnv"
  zone      = "ru-central1-a"
  service_account_key_file = file("~/.authorized_key.json")
}

resource "yandex_compute_instance" "vm-1" {
  name        = "vm1" #Имя ВМ в облачной консоли
  hostname    = "hw703" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3" #процессор

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
   }
  boot_disk {
    initialize_params {
      image_id = "fd870chete5dal4rjlkq"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  
  metadata = {
    user-data = file("/home/yury/Terraform/7-03a/meta.yaml")
  }

  # прерываемая
  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}