resource "yandex_vpc_network" "netology_diplom" {
  name        = "netology-diplom"
  description = "VPC network for Netology diplom project"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.netology_diplom.id
  v4_cidr_blocks = ["10.10.1.0/24"]
  description    = "Subnet A in zone ru-central1-a"
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.netology_diplom.id
  v4_cidr_blocks = ["10.10.2.0/24"]
  description    = "Subnet B in zone ru-central1-b"
}

resource "yandex_vpc_subnet" "subnet_c" {
  name           = "subnet-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.netology_diplom.id
  v4_cidr_blocks = ["10.10.3.0/24"]
  description    = "Subnet C in zone ru-central1-c"
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.netology_diplom.id
  v4_cidr_blocks = ["10.10.4.0/24"]
  description    = "Subnet D in zone ru-central1-d"
}
