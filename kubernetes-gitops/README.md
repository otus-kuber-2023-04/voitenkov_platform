# Выполнено ДЗ № 11

 - [x] Основное ДЗ
 - [x] Задание со ⭐ (Подготовка Kubernetes кластера)
 - [x] Задание сo ⭐ (Continuous Integration)
 - [ ] Задание сo ⭐ (Установка Istio)
 - [ ] Дополнительное задание сo ⭐ (Flagger еще один микросервис)
 - [ ] Дополнительное задание сo ⭐ (Flagger нотификации в Slack)
 - [ ] Дополнительное задание сo ⭐ (Инфраструктурный репозиторий)
 - [ ] Дополнительное задание сo ⭐ (Distributed Tracing)
 - [ ] Дополнительное задание с ⭐⭐ (Monorepos: Please don’t!)
 - [ ] Дополнительное задание с ⭐⭐ (ArgoCD)

## В процессе сделано:

### Подготовка инфраструктуры

Использованы мои наработки из дипломного проекта по курсу **DevOps для эксплуатации и разработки**.

Кластер Kubernetes поднимается в облаке Yandex Cloud. Вся инфраструктура разворачивается по методолгии IaaC с использованием Terraform:
1. Административное облако **organization** для размещения административного фолдера **adm-folder** для ресурсов уровня организации (облака)
2. **adm-folder** в облаке **organization** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 1 (организация и описание облаков для проектов)
3. Облако проекта **otus-kuber** для размещения административного фолдера **adm-folder** для ресурсов уровня проекта (фолдеры) и фолдеров окружений проекта
4. **adm-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 2 (облако проекта и описание фолдеров окружений проекта)
5. **dev-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Development окружения проекта и описание ресурсов этого фолдера)
6. **prod-folder** в облаке **otus-kuber** для размещения объектного хранилища, на котором сохраняется Terraform state уровня 3 (фолдер Production окружения проекта и описание ресурсов этого фолдера)
7. Ресурсы **Development** окружения проекта:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - compute инстанс (виртуальная машина) с предустановленным через UserData template-file набором утилит для DevOp-инженера (yandex cli, kubectl, helm, go, etc.)      
8. Ресурсы **Production** окружения проекта:
  - сеть и подсеть
  - сервисные аккаунты
  - группы безопасности
  - Managed Kubernetes cluster
  - зона и записи DNS
    
    В кластере Managed Kubernetes развернуты 1 нодгруппа с включенным автоскалированием нод:
    - default-pool - от 0 до 4     
    
![Yandex.Cloud](/images/hw09-yandex-cloud.png)  

Подробнее по инфраструктурной части см. https://github.com/otus-kuber-2023-04/voitenkov_platform/blob/kubernetes-templating/infrastructure/README.md

## Решение Д/З № 11

### Подготовка Kubernetes кластера | Задание со ⭐

Автоматизируйте создание Kubernetes кластера
Кластер должен разворачиваться после запуска pipeline в GitLab
Инфраструктурный код и файл .gitlab-ci.yaml поместите в отдельный репозиторий и приложите ссылку на данный репозиторий в PR

Для автоматизации было сделано:
- Terraform'ом (пока вручную) в Development-окружении создана виртуальная машина, в ней установлен и подключен Gitlab-Runner.
- Настроена интеграция Gitlab с Terraform с использованием готового шаблона. Репозиторий GitLab можно посмотреть https://gitlab.com/voitenkov/microservices-demo . 

Структура репозитория:
```
application - application part of repo
├── .gitlab-ci - microservices pipelines
├── ... - application source code
clusters - GitOps part of repo (and Flux-controlled applications)
├── production 
    ├── flux-system - Flux v2 manifests 
    ├── releases - HelmReleses to be deployed by Flux
    ├── ... - manifests to be deployed by Flux
infrastructure - infrastructure part of repo
├──.gitlab-ci - pipelines for infrastructure deploy (terraform intergration)
├── 1-organization - Organization level Terraform project (to create new clouds within different organizations)
├── 2-cloud - Cloud level Terraform project (to create new folders within specific cloud)
├── 3-development - Development environment level Terraform project (to deploy Development infrastructure within specific cloud)
├── 4-production - Production environment level Terraform project (to deploy Production infrastructure within specific cloud)
├── deploy 
│   ├── charts - Helm charts to deploy applications in Kubernetes
├── images - application images to upload to YC S3 object storage
├── modules - common Terraform modules to use in Terraform projects
│   ├── bucket - for YC object sorage
│   ├── cloud - for YC cloud resourse 
│   ├── folder - for YC folder resourse 
│   ├── instance - for YC compute instance 
│   ├── k8s-cluster - for YC Managed Kubernetes cluster
│   ├── k8s-node - for YC Managed Kubernetes cluster node group
│   ├── sa - for YC service account
│   ├── subnet - for YC VPC subnet
├── templates - cloud-init userdata templates to use in instances deploymnet
.gitlab-ci - Main downstream pipline
```
 
Сам файл .gitlab-ci.yaml
```
include:
  - template: Terraform.latest.gitlab-ci.yml

variables:
  TF_STATE_NAME: default
  TF_CACHE_KEY: default
  TF_ROOT: "infrastructure/4-production"

before_script:
  - |
    cat <<EOF >> ~/.terraformrc
    provider_installation {
      network_mirror {
        url = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
      }
      direct {
        exclude = ["registry.terraform.io/*/*"]
      }
    }
    EOF
  - echo "$YC_IAM_KEY" > ~/key.json
  - echo "$SSH_PUBLIC_KEY" > ~/id_rsa.pub

```













## Как проверить работоспособность:
 - см. выше
## PR checklist:
 - [x] Выставлен label с темой домашнего задания
