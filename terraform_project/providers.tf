terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.117.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "bucket-dp-vmaltsev"
    region     = "ru-central1-a"
    key        = "terraform.tfstate.d/default/terraform.tfstate"
    access_key = "YCAJEseCKLK3JuQzJAyfJZ3OI"
    secret_key = "YCOqRm_h3cKRlZm2ZsRgRC9p4agQnoxZ1mzlCLw3"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("~/key.json")
}
