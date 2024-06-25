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

resource "yandex_compute_instance" "cp" {
  name = "control"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet_a.id
    nat        = true
  }

  metadata = {
    user-data = file("meta.txt")
  }

  description = "Control plane instance"
}

resource "yandex_compute_instance" "node1" {
  name = "workernode1"
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 15
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet_b.id
    nat        = true
  }

  metadata = {
    user-data = file("meta.txt")
  }

  scheduling_policy {
    preemptible = true
  }

  description = "Worker node 1"
}

resource "yandex_compute_instance" "node2" {
  name        = "workernode2"
  zone        = "ru-central1-d"
  platform_id = "standard-v2"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 15
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet_d.id
    nat        = true
  }

  metadata = {
    user-data = file("meta.txt")
  }

  scheduling_policy {
    preemptible = true
  }

  description = "Worker node 2"
}
