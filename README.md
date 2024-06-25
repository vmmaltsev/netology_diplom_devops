# Дипломный практикум в Yandex.Cloud - Мальцев Виктор
- [Дипломный практикум в Yandex.Cloud - Мальцев Виктор](#дипломный-практикум-в-yandexcloud---мальцев-виктор)
  - [Цели:](#цели)
  - [Этапы выполнения:](#этапы-выполнения)
    - [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
    - [Создание Kubernetes кластера](#создание-kubernetes-кластера)
    - [Создание тестового приложения](#создание-тестового-приложения)
    - [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
    - [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  - [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:

### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя

Результаты выполнения:

   * Создан сервисный аккаунт с использованием Yandex CLI
   * Сервисному аккаунту назначены права на соотвествующий проект с использованием Yandex CLI
   * Сгенерирован ключ, который будет использован для работы Terraform

```bash
ubuntu@instance-20240625-081433:~$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Downloading yc 0.127.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 78.7M  100 78.7M    0     0  15.3M      0  0:00:05  0:00:05 --:--:-- 16.4M
Yandex Cloud CLI 0.127.0 linux/amd64

yc PATH has been added to your '/home/ubuntu/.bashrc' profile
yc bash completion has been added to your '/home/ubuntu/.bashrc' profile.
Now we have zsh completion. Type "echo 'source /home/ubuntu/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install itTo complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/ubuntu/.bashrc"' in the current one
```

```bash
ubuntu@instance-20240625-081433:~$ exec -l $SHELL
```

```bash
ubuntu@instance-20240625-081433:~$ yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb in order to obtain OAuth token.
 Please enter OAuth token: y0_A____c
You have one cloud available: 'cloud-nphne-xquks5er' (id = b1gnvmu4oqhl48jdq4s6). It is going to be used by default.
You have no available folders. You will be guided through creating one.
Please enter a folder name: project
Your current folder has been set to 'project' (id = b1guke85m20c3oiopip5).
Do you want to configure a default Compute zone? [Y/n] y
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-c
 [4] ru-central1-d
 [5] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
```

```bash
ubuntu@instance-20240625-081433:~$ yc iam service-account create --name admin
done (2s)
id: ajevambqvldr7h4feaha
folder_id: b1guke85m20c3oiopip5
created_at: "2024-06-25T09:00:08.577023980Z"
name: admin
```

```bash
ubuntu@instance-20240625-081433:~$ yc resource-manager folder add-access-binding b1guke85m20c3oiopip5 --role admin --subject serviceAccount:ajevambqvldr7h4feaha
done (4s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: admin
      subject:
        id: ajevambqvldr7h4feaha
        type: serviceAccount
```

```bash
ubuntu@instance-20240625-081433:~$ yc iam key create \
  --service-account-id ajevambqvldr7h4feaha \
  --folder-name project \
  --output key.json
id: aje3poo558nq3jis53q8
service_account_id: ajevambqvldr7h4feaha
created_at: "2024-06-25T09:05:04.600913614Z"
key_algorithm: RSA_2048
```

2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)

Результаты выполнения:

 * С помощью Terraform создан бакет S3
  
   Конфигурационные файлы расположены в директории по ссылке: https://github.com/vmmaltsev/netology_diplom_devops/tree/main/terraform_bucket

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_bucket$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.117.0"...
- Installing yandex-cloud/yandex v0.117.0...
- Installed yandex-cloud/yandex v0.117.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_bucket$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_iam_service_account.sa will be created
  + resource "yandex_iam_service_account" "sa" {
      + created_at = (known after apply)
      + folder_id  = "b1guke85m20c3oiopip5"
      + id         = (known after apply)
      + name       = "dp-sa"
    }

  # yandex_iam_service_account_static_access_key.sa-static-key will be created
  + resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
      + access_key           = (known after apply)
      + created_at           = (known after apply)
      + description          = "Static access key for object storage"
      + encrypted_secret_key = (known after apply)
      + id                   = (known after apply)
      + key_fingerprint      = (known after apply)
      + secret_key           = (sensitive value)
      + service_account_id   = (known after apply)
    }

  # yandex_resourcemanager_folder_iam_member.sa-editor will be created
  + resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
      + folder_id = "b1guke85m20c3oiopip5"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "storage.editor"
    }

  # yandex_storage_bucket.bucket will be created
  + resource "yandex_storage_bucket" "bucket" {
      + access_key            = (known after apply)
      + bucket                = "bucket-dp-vmaltsev"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + service_account_access_key = (sensitive value)
  + service_account_secret_key = (sensitive value)

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_bucket$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_iam_service_account.sa will be created
  + resource "yandex_iam_service_account" "sa" {
      + created_at = (known after apply)
      + folder_id  = "b1guke85m20c3oiopip5"
      + id         = (known after apply)
      + name       = "dp-sa"
    }

  # yandex_iam_service_account_static_access_key.sa-static-key will be created
  + resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
      + access_key           = (known after apply)
      + created_at           = (known after apply)
      + description          = "Static access key for object storage"
      + encrypted_secret_key = (known after apply)
      + id                   = (known after apply)
      + key_fingerprint      = (known after apply)
      + secret_key           = (sensitive value)
      + service_account_id   = (known after apply)
    }

  # yandex_resourcemanager_folder_iam_member.sa-editor will be created
  + resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
      + folder_id = "b1guke85m20c3oiopip5"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "storage.editor"
    }

  # yandex_storage_bucket.bucket will be created
  + resource "yandex_storage_bucket" "bucket" {
      + access_key            = (known after apply)
      + bucket                = "bucket-dp-vmaltsev"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + service_account_access_key = (sensitive value)
  + service_account_secret_key = (sensitive value)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_iam_service_account.sa: Creating...
yandex_iam_service_account.sa: Creation complete after 5s [id=ajelc1fua53vm52vmobr]
yandex_resourcemanager_folder_iam_member.sa-editor: Creating...
yandex_iam_service_account_static_access_key.sa-static-key: Creating...
yandex_iam_service_account_static_access_key.sa-static-key: Creation complete after 1s [id=ajeh447jsa5qgqbog4ia]
yandex_storage_bucket.bucket: Creating...
yandex_resourcemanager_folder_iam_member.sa-editor: Creation complete after 4s [id=b1guke85m20c3oiopip5/storage.editor/serviceAccount:ajelc1fua53vm52vmobr]
yandex_storage_bucket.bucket: Still creating... [10s elapsed]
yandex_storage_bucket.bucket: Still creating... [20s elapsed]
yandex_storage_bucket.bucket: Still creating... [30s elapsed]
yandex_storage_bucket.bucket: Still creating... [40s elapsed]
yandex_storage_bucket.bucket: Still creating... [50s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m0s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m10s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m20s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m30s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m40s elapsed]
yandex_storage_bucket.bucket: Still creating... [1m50s elapsed]
yandex_storage_bucket.bucket: Still creating... [2m0s elapsed]
yandex_storage_bucket.bucket: Creation complete after 2m6s [id=bucket-dp-vmaltsev]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

service_account_access_key = <sensitive>
service_account_secret_key = <sensitive>
```

3. Создайте VPC с подсетями в разных зонах доступности.

Результаты выполнения:

 * С помощью Terraform создана VPC и подсети во всех зонах доступности, при этом используется backend в бакете. Для этого необходимо предварительно выгрузить ключи, которые созданы при создании бакета, а также сохранены с помощью файла outputs.tf.
  Для этого необходимо использовать команды:

```bash
terraform output service_account_access_key
terraform output service_account_secret_key
```
  
   Конфигурационные файлы расположены в директории по ссылке: https://github.com/vmmaltsev/netology_diplom_devops/tree/main/terraform_project

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform init

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.117.0"...
- Installing yandex-cloud/yandex v0.117.0...
- Installed yandex-cloud/yandex v0.117.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_vpc_network.netology_diplom will be created
  + resource "yandex_vpc_network" "netology_diplom" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "VPC network for Netology diplom project"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "netology-diplom"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet_a will be created
  + resource "yandex_vpc_subnet" "subnet_a" {
      + created_at     = (known after apply)
      + description    = "Subnet A in zone ru-central1-a"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet_b will be created
  + resource "yandex_vpc_subnet" "subnet_b" {
      + created_at     = (known after apply)
      + description    = "Subnet B in zone ru-central1-b"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet_c will be created
  + resource "yandex_vpc_subnet" "subnet_c" {
      + created_at     = (known after apply)
      + description    = "Subnet C in zone ru-central1-c"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-c"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-c"
    }

  # yandex_vpc_subnet.subnet_d will be created
  + resource "yandex_vpc_subnet" "subnet_d" {
      + created_at     = (known after apply)
      + description    = "Subnet D in zone ru-central1-d"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.4.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_vpc_network.netology_diplom will be created
  + resource "yandex_vpc_network" "netology_diplom" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "VPC network for Netology diplom project"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "netology-diplom"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet_a will be created
  + resource "yandex_vpc_subnet" "subnet_a" {
      + created_at     = (known after apply)
      + description    = "Subnet A in zone ru-central1-a"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet_b will be created
  + resource "yandex_vpc_subnet" "subnet_b" {
      + created_at     = (known after apply)
      + description    = "Subnet B in zone ru-central1-b"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet_c will be created
  + resource "yandex_vpc_subnet" "subnet_c" {
      + created_at     = (known after apply)
      + description    = "Subnet C in zone ru-central1-c"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-c"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-c"
    }

  # yandex_vpc_subnet.subnet_d will be created
  + resource "yandex_vpc_subnet" "subnet_d" {
      + created_at     = (known after apply)
      + description    = "Subnet D in zone ru-central1-d"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.4.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.netology_diplom: Creating...
yandex_vpc_network.netology_diplom: Creation complete after 5s [id=enpk35ur92q1pfkagfnf]
yandex_vpc_subnet.subnet_c: Creating...
yandex_vpc_subnet.subnet_b: Creating...
yandex_vpc_subnet.subnet_d: Creating...
yandex_vpc_subnet.subnet_a: Creating...
yandex_vpc_subnet.subnet_c: Creation complete after 0s [id=b0cuqrsdt8o1ujtle72o]
yandex_vpc_subnet.subnet_b: Creation complete after 1s [id=e2ldr27ng5v9deejvlk0]
yandex_vpc_subnet.subnet_a: Creation complete after 1s [id=e9bm59g22peq0vq2aeu7]
yandex_vpc_subnet.subnet_d: Creation complete after 2s [id=fl8cfru5saenm9a6ggra]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.

   В результате destroy и apply проходит без дополнительных действий.

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform destroy
yandex_vpc_network.netology_diplom: Refreshing state... [id=enpk35ur92q1pfkagfnf]
yandex_vpc_subnet.subnet_a: Refreshing state... [id=e9bm59g22peq0vq2aeu7]
yandex_vpc_subnet.subnet_c: Refreshing state... [id=b0cuqrsdt8o1ujtle72o]
yandex_vpc_subnet.subnet_d: Refreshing state... [id=fl8cfru5saenm9a6ggra]
yandex_vpc_subnet.subnet_b: Refreshing state... [id=e2ldr27ng5v9deejvlk0]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_vpc_network.netology_diplom will be destroyed
  - resource "yandex_vpc_network" "netology_diplom" {
      - created_at                = "2024-06-25T09:44:50Z" -> null
      - default_security_group_id = "enpiore39ke42ghdl2fp" -> null
      - description               = "VPC network for Netology diplom project" -> null
      - folder_id                 = "b1guke85m20c3oiopip5" -> null
      - id                        = "enpk35ur92q1pfkagfnf" -> null
      - labels                    = {} -> null
      - name                      = "netology-diplom" -> null
      - subnet_ids                = [
          - "b0cuqrsdt8o1ujtle72o",
          - "e2ldr27ng5v9deejvlk0",
          - "e9bm59g22peq0vq2aeu7",
          - "fl8cfru5saenm9a6ggra",
        ] -> null
    }

  # yandex_vpc_subnet.subnet_a will be destroyed
  - resource "yandex_vpc_subnet" "subnet_a" {
      - created_at     = "2024-06-25T09:44:52Z" -> null
      - description    = "Subnet A in zone ru-central1-a" -> null
      - folder_id      = "b1guke85m20c3oiopip5" -> null
      - id             = "e9bm59g22peq0vq2aeu7" -> null
      - labels         = {} -> null
      - name           = "subnet-a" -> null
      - network_id     = "enpk35ur92q1pfkagfnf" -> null
      - v4_cidr_blocks = [
          - "10.10.1.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-a" -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_subnet.subnet_b will be destroyed
  - resource "yandex_vpc_subnet" "subnet_b" {
      - created_at     = "2024-06-25T09:44:52Z" -> null
      - description    = "Subnet B in zone ru-central1-b" -> null
      - folder_id      = "b1guke85m20c3oiopip5" -> null
      - id             = "e2ldr27ng5v9deejvlk0" -> null
      - labels         = {} -> null
      - name           = "subnet-b" -> null
      - network_id     = "enpk35ur92q1pfkagfnf" -> null
      - v4_cidr_blocks = [
          - "10.10.2.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-b" -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_subnet.subnet_c will be destroyed
  - resource "yandex_vpc_subnet" "subnet_c" {
      - created_at     = "2024-06-25T09:44:52Z" -> null
      - description    = "Subnet C in zone ru-central1-c" -> null
      - folder_id      = "b1guke85m20c3oiopip5" -> null
      - id             = "b0cuqrsdt8o1ujtle72o" -> null
      - labels         = {} -> null
      - name           = "subnet-c" -> null
      - network_id     = "enpk35ur92q1pfkagfnf" -> null
      - v4_cidr_blocks = [
          - "10.10.3.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-c" -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_subnet.subnet_d will be destroyed
  - resource "yandex_vpc_subnet" "subnet_d" {
      - created_at     = "2024-06-25T09:44:53Z" -> null
      - description    = "Subnet D in zone ru-central1-d" -> null
      - folder_id      = "b1guke85m20c3oiopip5" -> null
      - id             = "fl8cfru5saenm9a6ggra" -> null
      - labels         = {} -> null
      - name           = "subnet-d" -> null
      - network_id     = "enpk35ur92q1pfkagfnf" -> null
      - v4_cidr_blocks = [
          - "10.10.4.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-d" -> null
        # (1 unchanged attribute hidden)
    }

Plan: 0 to add, 0 to change, 5 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

yandex_vpc_subnet.subnet_b: Destroying... [id=e2ldr27ng5v9deejvlk0]
yandex_vpc_subnet.subnet_c: Destroying... [id=b0cuqrsdt8o1ujtle72o]
yandex_vpc_subnet.subnet_a: Destroying... [id=e9bm59g22peq0vq2aeu7]
yandex_vpc_subnet.subnet_d: Destroying... [id=fl8cfru5saenm9a6ggra]
yandex_vpc_subnet.subnet_d: Destruction complete after 2s
yandex_vpc_subnet.subnet_a: Destruction complete after 2s
yandex_vpc_subnet.subnet_b: Destruction complete after 2s
yandex_vpc_subnet.subnet_c: Destruction complete after 3s
yandex_vpc_network.netology_diplom: Destroying... [id=enpk35ur92q1pfkagfnf]
yandex_vpc_network.netology_diplom: Destruction complete after 1s

Destroy complete! Resources: 5 destroyed.
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_vpc_network.netology_diplom will be created
  + resource "yandex_vpc_network" "netology_diplom" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "VPC network for Netology diplom project"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "netology-diplom"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet_a will be created
  + resource "yandex_vpc_subnet" "subnet_a" {
      + created_at     = (known after apply)
      + description    = "Subnet A in zone ru-central1-a"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet_b will be created
  + resource "yandex_vpc_subnet" "subnet_b" {
      + created_at     = (known after apply)
      + description    = "Subnet B in zone ru-central1-b"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet_c will be created
  + resource "yandex_vpc_subnet" "subnet_c" {
      + created_at     = (known after apply)
      + description    = "Subnet C in zone ru-central1-c"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-c"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-c"
    }

  # yandex_vpc_subnet.subnet_d will be created
  + resource "yandex_vpc_subnet" "subnet_d" {
      + created_at     = (known after apply)
      + description    = "Subnet D in zone ru-central1-d"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.4.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_vpc_network.netology_diplom: Creating...
yandex_vpc_network.netology_diplom: Creation complete after 4s [id=enpm3e7mp0alc2v079b9]
yandex_vpc_subnet.subnet_d: Creating...
yandex_vpc_subnet.subnet_a: Creating...
yandex_vpc_subnet.subnet_b: Creating...
yandex_vpc_subnet.subnet_c: Creating...
yandex_vpc_subnet.subnet_b: Creation complete after 0s [id=e2ld7je9e0fhgrvgf4f7]
yandex_vpc_subnet.subnet_c: Creation complete after 1s [id=b0cn7s1mjcltcqjgeusa]
yandex_vpc_subnet.subnet_d: Creation complete after 1s [id=fl8j2p6r9i7m28lvru14]
yandex_vpc_subnet.subnet_a: Creation complete after 2s [id=e9b11it1nfb2063agnml]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
   * Terraform сконфигурирован

2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.
   * Получена предварительная конфигурация из сети и подсетей во всех зонах доступности

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.

   В предыдущей части задания была создана виртуальная сеть, в рамках выполнения этой части конфигурационные файлы будут дополнены для создания 3 виртуальных машин.
   Конфигурационные файлы расположены в директории по ссылке: https://github.com/vmmaltsev/netology_diplom_devops/tree/main/terraform_project

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform plan
yandex_vpc_network.netology_diplom: Refreshing state... [id=enpm3e7mp0alc2v079b9]
yandex_vpc_subnet.subnet_c: Refreshing state... [id=b0cn7s1mjcltcqjgeusa]
yandex_vpc_subnet.subnet_d: Refreshing state... [id=fl8j2p6r9i7m28lvru14]
yandex_vpc_subnet.subnet_b: Refreshing state... [id=e2ld7je9e0fhgrvgf4f7]
yandex_vpc_subnet.subnet_a: Refreshing state... [id=e9b11it1nfb2063agnml]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.cp will be created
  + resource "yandex_compute_instance" "cp" {
      + created_at                = (known after apply)
      + description               = "Control plane instance"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "control"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9b11it1nfb2063agnml"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }
    }

  # yandex_compute_instance.node1 will be created
  + resource "yandex_compute_instance" "node1" {
      + created_at                = (known after apply)
      + description               = "Worker node 1"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "workernode1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 15
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e2ld7je9e0fhgrvgf4f7"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.node2 will be created
  + resource "yandex_compute_instance" "node2" {
      + created_at                = (known after apply)
      + description               = "Worker node 2"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "workernode2"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-d"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 15
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "fl8j2p6r9i7m28lvru14"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform apply
yandex_vpc_network.netology_diplom: Refreshing state... [id=enpm3e7mp0alc2v079b9]
yandex_vpc_subnet.subnet_d: Refreshing state... [id=fl8j2p6r9i7m28lvru14]
yandex_vpc_subnet.subnet_a: Refreshing state... [id=e9b11it1nfb2063agnml]
yandex_vpc_subnet.subnet_c: Refreshing state... [id=b0cn7s1mjcltcqjgeusa]
yandex_vpc_subnet.subnet_b: Refreshing state... [id=e2ld7je9e0fhgrvgf4f7]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.cp will be created
  + resource "yandex_compute_instance" "cp" {
      + created_at                = (known after apply)
      + description               = "Control plane instance"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "control"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 20
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9b11it1nfb2063agnml"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }
    }

  # yandex_compute_instance.node1 will be created
  + resource "yandex_compute_instance" "node1" {
      + created_at                = (known after apply)
      + description               = "Worker node 1"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "workernode1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 15
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e2ld7je9e0fhgrvgf4f7"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.node2 will be created
  + resource "yandex_compute_instance" "node2" {
      + created_at                = (known after apply)
      + description               = "Worker node 2"
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: admin
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOriuzKlzfyHw5AcDjeMGPaakLMN/YT6a4e+Uad+4Wq5 ubuntu@instance-20240625-081433
            EOT
        }
      + name                      = "workernode2"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-d"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8idq8k33m9hlj0huli"
              + name        = (known after apply)
              + size        = 15
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "fl8j2p6r9i7m28lvru14"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_compute_instance.node1: Creating...
yandex_compute_instance.node2: Creating...
yandex_compute_instance.cp: Creating...
yandex_compute_instance.node1: Still creating... [10s elapsed]
yandex_compute_instance.node2: Still creating... [10s elapsed]
yandex_compute_instance.cp: Still creating... [10s elapsed]
yandex_compute_instance.node1: Still creating... [20s elapsed]
yandex_compute_instance.node2: Still creating... [20s elapsed]
yandex_compute_instance.cp: Still creating... [20s elapsed]
yandex_compute_instance.node1: Still creating... [30s elapsed]
yandex_compute_instance.node2: Still creating... [30s elapsed]
yandex_compute_instance.cp: Still creating... [30s elapsed]
yandex_compute_instance.node1: Still creating... [40s elapsed]
yandex_compute_instance.node2: Still creating... [40s elapsed]
yandex_compute_instance.cp: Still creating... [40s elapsed]
yandex_compute_instance.node1: Creation complete after 44s [id=epdbvrpi63v5og6ud6dp]
yandex_compute_instance.cp: Creation complete after 45s [id=fhmsmisbjlpc2blpoho6]
yandex_compute_instance.node2: Still creating... [50s elapsed]
yandex_compute_instance.node2: Creation complete after 51s [id=fv4s7u8vs9jvmpvv0sv7]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform plan
yandex_vpc_network.netology_diplom: Refreshing state... [id=enpm3e7mp0alc2v079b9]
yandex_vpc_subnet.subnet_a: Refreshing state... [id=e9b11it1nfb2063agnml]
yandex_vpc_subnet.subnet_b: Refreshing state... [id=e2ld7je9e0fhgrvgf4f7]
yandex_vpc_subnet.subnet_d: Refreshing state... [id=fl8j2p6r9i7m28lvru14]
yandex_vpc_subnet.subnet_c: Refreshing state... [id=b0cn7s1mjcltcqjgeusa]
yandex_compute_instance.node1: Refreshing state... [id=epdbvrpi63v5og6ud6dp]
yandex_compute_instance.cp: Refreshing state... [id=fhmsmisbjlpc2blpoho6]
yandex_compute_instance.node2: Refreshing state... [id=fv4s7u8vs9jvmpvv0sv7]

Changes to Outputs:
  + cp_external_ip    = "178.154.204.61"
  + cp_internal_ip    = "10.10.1.10"
  + node1_external_ip = "158.160.66.183"
  + node1_internal_ip = "10.10.2.31"
  + node2_external_ip = "158.160.137.231"
  + node2_internal_ip = "10.10.4.27"

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/terraform_project$ terraform apply
yandex_vpc_network.netology_diplom: Refreshing state... [id=enpm3e7mp0alc2v079b9]
yandex_vpc_subnet.subnet_a: Refreshing state... [id=e9b11it1nfb2063agnml]
yandex_vpc_subnet.subnet_c: Refreshing state... [id=b0cn7s1mjcltcqjgeusa]
yandex_vpc_subnet.subnet_d: Refreshing state... [id=fl8j2p6r9i7m28lvru14]
yandex_vpc_subnet.subnet_b: Refreshing state... [id=e2ld7je9e0fhgrvgf4f7]
yandex_compute_instance.cp: Refreshing state... [id=fhmsmisbjlpc2blpoho6]
yandex_compute_instance.node2: Refreshing state... [id=fv4s7u8vs9jvmpvv0sv7]
yandex_compute_instance.node1: Refreshing state... [id=epdbvrpi63v5og6ud6dp]

Changes to Outputs:
  + cp_external_ip    = "178.154.204.61"
  + cp_internal_ip    = "10.10.1.10"
  + node1_external_ip = "158.160.66.183"
  + node1_internal_ip = "10.10.2.31"
  + node2_external_ip = "158.160.137.231"
  + node2_internal_ip = "10.10.4.27"

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes


Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

cp_external_ip = "178.154.204.61"
cp_internal_ip = "10.10.1.10"
node1_external_ip = "158.160.66.183"
node1_internal_ip = "10.10.2.31"
node2_external_ip = "158.160.137.231"
node2_internal_ip = "10.10.4.27"
```

   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/) 

   * Перед запуском Kuberspray на виртуальных машинах нужно провести предварительные работы, которые будут выполненены с playbook в директории по ссылке:

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/ansible_prepare_kuberspray$ ansible-playbook -i inventory.yml set_hostname_and_update_hosts.yml

PLAY [Set hostname and update /etc/hosts and template] ****************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************************
ok: [node1]
ok: [node2]
ok: [cp]

TASK [Set hostname on cp] *********************************************************************************************************************************************************************************************
skipping: [node1]
skipping: [node2]
ok: [cp]

TASK [Set hostname on node1] ******************************************************************************************************************************************************************************************
skipping: [cp]
skipping: [node2]
ok: [node1]

TASK [Set hostname on node2] ******************************************************************************************************************************************************************************************
skipping: [cp]
skipping: [node1]
ok: [node2]

TASK [Ensure /etc/hosts contains the necessary entries] ***************************************************************************************************************************************************************
ok: [node2] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [cp] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [node1] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [node2] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [cp] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [node1] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [node2] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)
ok: [cp] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)
ok: [node1] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)

TASK [Ensure /etc/cloud/templates/hosts.debian.tmpl contains the necessary entries] ***********************************************************************************************************************************
ok: [cp] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [node2] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [node1] => (item=10.10.1.10   k8smaster.example.net k8smaster)
ok: [cp] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [node2] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [node1] => (item=10.10.2.31   k8sworker1.example.net k8sworker1)
ok: [node2] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)
ok: [cp] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)
ok: [node1] => (item=10.10.4.27   k8sworker2.example.net k8sworker2)

TASK [Reboot the server] **********************************************************************************************************************************************************************************************
changed: [node2]
changed: [cp]
changed: [node1]

PLAY RECAP ************************************************************************************************************************************************************************************************************
cp                         : ok=5    changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
node1                      : ok=5    changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
node2                      : ok=5    changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0 
```

```bash
ubuntu@instance-20240625-081433:~/netology_diplom_devops/ansible_prepare_kuberspray$ ansible-playbook -i inventory.yml disable_swap_and_add_kernel_parameters.yml

PLAY [Disable Swap & Add kernel Parameters] ***************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************************
ok: [node2]
ok: [cp]
ok: [node1]

TASK [Disable swap] ***************************************************************************************************************************************************************************************************
changed: [cp]
changed: [node2]
changed: [node1]

TASK [Comment out swap entry in /etc/fstab] ***************************************************************************************************************************************************************************
changed: [node2]
changed: [node1]
changed: [cp]

TASK [Create containerd modules-load configuration] *******************************************************************************************************************************************************************
changed: [cp]
changed: [node2]
changed: [node1]

TASK [Load overlay module] ********************************************************************************************************************************************************************************************
changed: [cp]
changed: [node2]
changed: [node1]

TASK [Load br_netfilter module] ***************************************************************************************************************************************************************************************
changed: [cp]
changed: [node2]
changed: [node1]

TASK [Check if Kubernetes sysctl configuration file exists] ***********************************************************************************************************************************************************
ok: [cp]
ok: [node2]
ok: [node1]

TASK [Set Kubernetes kernel parameters] *******************************************************************************************************************************************************************************
changed: [cp]
changed: [node2]
changed: [node1]

TASK [Reload sysctl settings] *****************************************************************************************************************************************************************************************
changed: [node2]
changed: [cp]
changed: [node1]

PLAY RECAP ************************************************************************************************************************************************************************************************************
cp                         : ok=9    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
node1                      : ok=9    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Дальнейшие действия выполняются с помощью Kuberspray.
Для этого необходимо склонировать репозиторий https://github.com/kubernetes-sigs/kubespray.git

Преварительно выполнить команды:

```bash
VENVDIR=kubespray-venv
KUBESPRAYDIR=kubespray
python3 -m venv $VENVDIR
source $VENVDIR/bin/activate
cd $KUBESPRAYDIR
pip install -U -r requirements.txt
```

Далее выполняем команду:

```bash
cp -rfp inventory/sample inventory/mycluster
```

Далее выполняем команды:

```bash
declare -a IPS=(178.154.204.61 158.160.66.183 158.160.137.231)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

Правим полученный файл под нужды текущей задачи /home/ubuntu/netology_diplom_devops/kubespray/inventory/mycluster/hosts.yaml

```bash
all:
  hosts:
    cp1:
      ansible_host: 178.154.204.61
      ip: 10.10.1.10
    node1:
      ansible_host: 158.160.66.183
      ip: 10.10.2.31
    node2:
      ansible_host: 158.160.137.231
      ip: 10.10.4.27
  children:
    kube_control_plane:
      hosts:
        cp1:
    kube_node:
      hosts:
        node1:
        node2:
    etcd:
      hosts:
        cp1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
```

Прописываем пользователя для доступа к нодам в начале файла /home/ubuntu/netology_diplom_devops/kubespray/inventory/mycluster/group_vars/all/all.yml

Для доступа к кластеру извне нужно добавить параметр supplementary_addresses_in_ssl_keys: [178.154.204.61] в файл inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml, что является ip мастер ноды.

И далее запускаем установку Kubernetes командой:

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml
```

Результат выполнения:

```bash
PLAY RECAP ************************************************************************************************************************************************************************************************************
cp1                        : ok=632  changed=140  unreachable=0    failed=0    skipped=1112 rescued=0    ignored=6   
node1                      : ok=416  changed=87   unreachable=0    failed=0    skipped=672  rescued=0    ignored=1   
node2                      : ok=416  changed=87   unreachable=0    failed=0    skipped=668  rescued=0    ignored=1   
```

   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.

   Для работы с кластером необходимо на локальной машине установить kubectl.
   Копируем ~/.kube/config с мастер ноды командой:
```bash
mkdir -p ~/.kube && ssh admin@178.154.204.61 "sudo cat /root/.kube/config" >> ~/.kube/config
```

Получаем файл такого вида:

```bash
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJVUJGZ0x3ZWlvU293RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBMk1qVXhNVEl3TkRsYUZ3MHpOREEyTWpNeE1USTFORGxhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUQwb0dzOVNkQnJKVklRZTZMa3k1L2o3VTkxZ3p0ZnphTkd3K3YzVFhCRlBuaU14VERkVjNTZEMxYWIKYzNjQlp0ZkhwMFVnWWZ0Vy9WWEFQdkF6cWtzV1Y0dmZoYzNadnNRWnc0cTZwYzkvUEFaRE53MTFFZVNrd1RmagpqUkxCTlY2dG5qMmpPQ1U4MEJBM2dTRVFxdm81dEFGdEgzWDFPSXJTMFVMYW96cmVBeUZObUpoOTdFUE9nMCs1Cm5aQXBhby9PelZGMWwzSXR4eWljTkFyTDloSkJIamthR1RqVDJPdUlHTTN4THVoQ3RKYko0VE4xL2NLTzhXaGMKaFV6UHAwbVFPOThKSEdpb25ralRzVmdjRlJFVEYwMUd3aE1ULzBGSlFLcXNVb21DRXhSQ0hJcFBvcmgzUVZRdgplWTN0QjNMZlcySkJ1S09pL1MxdmJvYnpwTHd6QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSYklsc3c5ai9tYTVWT2tGMlpqREt6RWY3dExEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjBYdE5heTlQVgpiY3dvWDZ3R3lmZ2duS1h6SEljVjRkM3NtWFBHWlRnSEV3NGtxeFlZd0o0UGJIWUFNeHhnN1Jxa1BKZlIyelZaClRseVVJbm83SUkyeEtzb0NOUzZ3TlJGME1neG9vTjdDa0JIcDA5dUJ4czZOdGd2VUhjZGs4NEtsaVMwb1NYWGUKVS9MVzgrcGVGako4aEgvellveWp6OFh0RmQvb0F1QVNtbW9Vbk8wdHUvZHJqMGFIOVFSYTMxQ0g0L1QrZXM2awo0SG5CTXY1KzkrRm1zcmdQcVhyUDVtczcxYVZlelpSelAzYTNwdXM0VStnZHlaRzNYaDlhR01FVHpGNzVDS2h1CmVRUEc5cmEwaDcrU292cXlZOUxuV1ROMXRJWnVUalFyZnFVdGt1M251bjFFOWx4MHZNN1ZNcUdUZTBQcE51b0sKTm94ejNFWEhVem1UCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://127.0.0.1:6443
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubernetes-admin
  name: kubernetes-admin@cluster.local
current-context: kubernetes-admin@cluster.local
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURLVENDQWhHZ0F3SUJBZ0lJTE5uVnhkSTB1WVV3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBMk1qVXhNVEl3TkR
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBNWdpVVdiQ1BCc01IOVB5T2xhZ1QyNS96N1hkQlJYY1NLNWZBSUNJc0w5RGZvNzcwCkxkbk1xeElrTlE5UFRwTS95QlExQ2k4Mi9uelpCQ3ZBbW9
```
Заменяем ip на внешний ip мастер ноды:

```bash
https://178.154.204.61:6443
```

Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

Класер создан, доступно подключение через интернет.

```bash
ubuntu@instance-20240625-081433:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                       READY   STATUS    RESTARTS      AGE
kube-system   calico-kube-controllers-68485cbf9c-rxzrw   1/1     Running   0             24m
kube-system   calico-node-bghpx                          1/1     Running   0             25m
kube-system   calico-node-pdnkz                          1/1     Running   0             25m
kube-system   calico-node-qvlfm                          1/1     Running   0             25m
kube-system   coredns-69db55dd76-548sw                   1/1     Running   0             22m
kube-system   coredns-69db55dd76-qn8bv                   1/1     Running   0             22m
kube-system   dns-autoscaler-6f4b597d8c-5q85z            1/1     Running   0             22m
kube-system   kube-apiserver-cp1                         1/1     Running   2 (21m ago)   28m
kube-system   kube-controller-manager-cp1                1/1     Running   3 (21m ago)   28m
kube-system   kube-proxy-n6v4h                           1/1     Running   0             27m
kube-system   kube-proxy-v9zqb                           1/1     Running   0             27m
kube-system   kube-proxy-zv7pj                           1/1     Running   0             27m
kube-system   kube-scheduler-cp1                         1/1     Running   3 (21m ago)   28m
kube-system   nginx-proxy-node1                          1/1     Running   0             27m
kube-system   nginx-proxy-node2                          1/1     Running   0             27m
kube-system   nodelocaldns-2t52j                         1/1     Running   0             22m
kube-system   nodelocaldns-4nkn7                         1/1     Running   0             22m
kube-system   nodelocaldns-6gs5k                         1/1     Running   0             22m
ubuntu@instance-20240625-081433:~$ kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
cp1     Ready    control-plane   28m   v1.29.5
node1   Ready    <none>          27m   v1.29.5
node2   Ready    <none>          27m   v1.29.5
```

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ к тестовому приложению.

---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

