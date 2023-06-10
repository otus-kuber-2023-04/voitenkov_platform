# Infrastructure Part of Repository

## About the Project

This repository was developed to provide examples of how to deploy Kubernetes infrastructure platform (within OTUS learning course) to Yandex Cloud.

Organization structure and IAM have been taken _with some simplifications_ from Yandex Cloud reference design.
Pls see (https://github.com/yandex-cloud/yc-solution-library-for-security/blob/master/auth_and_access/org_iac_iam/README.md)

Organization structure consists of 3 clouds in Yandex Cloud organization account:
- default cloud (to bootstrap next organization entities)
- organization (to manage project clouds)
- otus-kuber (for Development and Production environments)

Default cloud has at least one initial Default folder.

Organization cloud has only one adm-folder with object storage to store Organization level Terraform state.

Otus-kuber cloud has 3 folders:
- adm-folder (with object storage to store Cloud level Terraform state)
- dev-folder (for Development environment)
- prod-folder (for Production environment)

Each of 4 Terraform state could be managed by 4 different admins:
- Organization level admin (to create new clouds for new projects)
- Cloud level admin (to create folders for different environments within the cloud)
- Development folder admin
- Production folder admin


![Reference](./images/yandex-cloud.png)

## Getting Started

Repository structure:
```
infrastructure
├── 1-organization - Organization level Terraform project (to create new clouds within different organizations)
│   ├── activate-yc-profile.ps1 - script (Windows) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── activate-yc-profile.sh - script (Linux) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── ... - files related to Terraform project
├── 2-cloud - Cloud level Terraform project (to create new folders within specific cloud)
│   ├── activate-yc-profile.ps1 - script (Windows) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── activate-yc-profile.sh - script (Linux) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── ... - files related to Terraform project
├── 3-development - Development environment level Terraform project (to deploy Development infrastructure within specific cloud)
│   ├── activate-yc-profile.ps1 - script (Windows) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── activate-yc-profile.sh - script (Linux) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── ... - files related to Terraform project
├── 4-production - Production environment level Terraform project (to deploy Production infrastructure within specific cloud)
│   ├── activate-yc-profile.ps1 - script (Windows) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── activate-yc-profile.sh - script (Linux) for initial configuration of Yandex Cloud CLI and OS environmental variables
│   ├── activate-alb.ps1 - script (Windows) to create service account key to access Yandex Cloud Container Registry
│   ├── activate-alb.sh - script (Linux) to install YC ALB ingress controller Helm chart
│   ├── ... - files related to Terraform project
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
```

## Installation Instructions

These instructions demonstrate how to deploy Kubernetes infrastructure platform into Yandex.Cloud.

**To be performed from your Windows or Linux personal computer**

### Pre-requisites (Powershell CLI for Windows or BASH or Other Shell for Linux Terminal)

1. Yandex Cloud command line interface - [yc cli](https://cloud.yandex.com/en/docs/cli/quickstart#install)
2. Terraform command line interface - [terraform cli](https://cloud.yandex.com/en/docs/tutorials/infrastructure-management/terraform-quickstart)
3. Configure Terraform provider to work with Yandex.Cloud (https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#configure-provider).
4. Create new account or prepare **cloud-owner user** credentials for existing Yandex.Cloud account.
5. To create new clouds in Yandex.Cloud with Terraform first cloud and folder should be created manually in [Yandex.Cloud web console](https://console.cloud.yandex.ru/). Initial cloud and folder are created automatically when creating new Yandex Cloud account.
6. **yc cli** profile with name **default** should be created to manage Yandex.Cloud account.
Pls run **yc init** command and follow interactive instructions to create **default** profile. OAuth token for Yandex.Cloud account will be asked.
7. Pls get **Organization ID** and **Billing account ID** from [Yandex.Cloud web console](https://console.cloud.yandex.ru/) to use them in Terraform in _infrastructure/1-organization/main.tf_
8. **git cli** - is provided in all modern Linux distributions. For Windows you may install it from [Download git for Windows] (https://git-scm.com/download/win)
9. Provide to GitLab project admin your personal SSH-public key from key pair stored on your computer user profile to add it to GitLab repository settings.

The rest tools will be installed automatically (by cloud-init scipts) on DevOps instance.


###  Create Administrative and Project Clouds within Yandex.Cloud Account Organization (Terraform)

Pls run following commands (Windows cmd commands will be used as examples, for Linux use relevant shell commands and provided scripts):
1. **git clone git@gitlab.praktikum-services.ru:std-010-065/momo-store.git**
2. **cd momo-store\infrastructure\1-organization**
3. **.\activate-yc-profile.ps1** # to create (activate) **momo-organization** yc profile and set environment variables with **OAuth-token**, **cloud-id** and default folder **folder-id**.
4. **copy versions.tf versions.s3** # and delete _backend "s3" {}_ section in **versions.tf**
5. **terraform init**
6. Open _infrastructure/1-organization/main.tf_ file and replace **cloud_organization_id** and **cloud_billing_account_id** with values from your YC account.
7. terraform apply

**organization** and **momo-store** clouds will be created. **adm-folder** and Object storage for Terraform state file will be created in both clouds. Pls open _infrastructure/1-organization/terraform.tfstate_, find 
```
"module": "module.organization-cloud",
"mode": "managed",
"type": "yandex_storage_bucket",
"name": "s3-tfstate",
...
        "access_key":"<access key>"
...
        "secret_key":"<secret key"
```
and
```
"module": "module.momo-cloud",
"mode": "managed",
"type": "yandex_storage_bucket",
"name": "s3-tfstate",
...
        "access_key":"<access key"
...
        "secret_key":"<secret key"
```
and take values of **"access_key"** and **"secret_key"** and save them in file in secured location.
Create **secrets.ps1** with following content replacing access and secret keys with values from **module.organization-cloud** section of **terraform.tfstate** file:
```
# Set static keys for access to TS state S3 storage 
$Env:AWS_ACCESS_KEY_ID     = "<access_key from module.organization-cloud>"
$Env:AWS_SECRET_ACCESS_KEY = "<secret_key from module.organization-cloud>"
[Environment]::SetEnvironmentVariable('AWS_ACCESS_KEY_ID', $Env:AWS_ACCESS_KEY_ID, 'User')
[Environment]::SetEnvironmentVariable('AWS_SECRET_ACCESS_KEY', $Env:AWS_SECRET_ACCESS_KEY, 'User')  
```

You may also create another **secrets.ps1** with access and secret keys with values from **module.momo-cloud** section of **terraform.tfstate** file to provide it for the person engaged in creation of folders in momo-store cloud (_/infrastructure/2-cloud - Cloud level Terraform project_).

8. **.\secrets.ps1** # to set environment variables with **access key** and **secret key**, to access to **organization** cloud S3 backend for Terraform state file in adm-folder.
9. **copy versions.s3 versions.tf**
10. **terraform init -migrate-state** # to store Terraform state file in relevant Yandex.Cloud S3 backend.


###  Create Development and Production Folders within momo-store Cloud (Terraform)

Pls run following commands:
1. **cd momo-store\infrastructure\2-cloud**
2. **.\activate-yc-profile.ps1** # to create (activate) **momo-cloud** yc profile and set environment variables with **OAuth-token** and **cloud-id**.
3.  **copy versions.tf versions.s3** # and delete _backend "s3" {}_ section in **versions.tf**
4. **terraform init**
5. **terraform apply**

**dev-folder** and **prod-folder** folders will be created in **momo-store** cloud. Object storage for Terraform state file will be created in both folders. Pls open_ _infrastructure/2-cloud/terraform.tfstate__, find access and secret keys for **dev-folder** and **prod-folder** s3-tfstate buckets and save them in secured location. You also have to prepare **secrets.ps1** scripts with keys for **dev-folder** and **prod-folder**.

6. **.\secrets.ps1** # to set environment variables with **access key** and **secret key**, provided to access to **momo-store** cloud S3 backend for Terraform state file in **adm-folder**.
7. **copy versions.s3 versions.tf**
8. **terraform init -migrate-state** # to store Terraform state file in relevant Yandex.Cloud S3 backend.

###  Deploy Development Environment (Terraform)

Pls run following commands. All terraform resourses can be created and modified **only** within **dev-folder** due to restricted permissions of YC service account used for Terraform provider:
1. **cd momo-store\infrastructure\3-development**
2. **.\activate-yc-profile.ps1** # to create (activate) **momo-dev** yc profile and set environment variables with **cloud-id** and **folder-id**.
3. **.\secrets.ps1** # to set environment variables with **access key** and **secret key**, provided to access to **momo-store** cloud S3 backend for Terraform state file in **dev-folder**.

copy **id_rsa.pub** file with ssh public key to momo-store\infrastructure\3-development\secrets\devops1. It will be copied to development DevOps engineer instance. In case of several DevOps engineers, pls create devops2, devops3 and so on folders with relevant key files.
Also **count** value in module **"devops-instance"** in **main.tf** should be changed to number of created instances.

4. **terraform init**
5. **terraform apply**

**DevOps** instances with all tools to deploy infrastructure in Kubernetes will be created, as well as all networks, subnets, service accounts and security groups. You can get **DevOps** instance IP address from Yandex Cloud web-console or from Terraform output **external_ip_address**.

###  Deploy Production Environment (Terraform)

Pls run following commands. All terraform resourses can be created and modified **only** within **prod-folder** due to restricted permissions of YC service account used for Terraform provider:
1. **cd momo-store\infrastructure\4-production**
2. **.\activate-yc-profile.ps1** # to create (activate) **momo-prod** yc profile and set environment variables with **cloud-id** and **folder-id**.
3. **.\secrets.ps1** # to set environment variables with **access key** and **secret key**, provided to access to **momo-store** cloud S3 backend for Terraform state file in **dev-folder**.

copy **id_rsa.pub** file with ssh public key to momo-store\infrastructure\4-production\secrets\devops1. It will be copied to Kubernetes cluster worker nodes to access them via SSH. In case of several DevOps engineers only one SSH key could be added for user **devops1**.

4. **terraform init**
5. **terraform apply**

Kubernetes cluster with group of 2 worker nodes will be created, as well as all necessary networks, subnets, service accounts, security groups and wildcard SSL-certificate for *.momo.voytenkov.ru registered domain. Also S3 object storage with web-site images will be created.
IP address for YC ALB ingress controller will be also created with name **ip-momo-store-prod-k8s-alb**. You can get it from Yandex Cloud web-console or **yc cli**. Pls also save following ID's. You may run following commands to get IDs to be replaced in Kubernetes ingresses annotations:

6. **yc vpc address get ip-momo-store-prod-k8s-alb** # to get static IP address to be used by YC ALB ingress controller and Kubernetes ingresses. 

7. **yc vpc subnet get subnet-momo-store-prod-a1** # to get subnet ID for Kubernetes ingresses.

To get security groups IDs for Kubernetes ingresses.

8. **yc vpc security-group get sg-momo-store-prod-k8s-main** 
9. **yc vpc security-group get sg-momo-store-prod-k8s-alb**
10. **yc cm certificate get cert-momo-store-prod-momo-voytenkov-ru** # to get cetificate ID for Kubernetes ingresses.

Pls ask admin of DNS server for voytenkov.ru zone to create (or modify) following DNS-records:

```
.momo.voytenkov.ru. 600 A <IP address>
_acme-challenge.momo.voytenkov.ru. 600 CNAME <certificate ID>.cm.yandexcloud.net.
```

Pls note that some time is need to issue Let's Encrypt certificate. When status of certificate will change to ISSUED, you may proceed with next steps. You can get certificate status in Yandex Cloud web console or with the command **yc cm certificate get cert-momo-store-prod-momo-voytenkov-ru**.


###  Deploy and Configure Argocd (Helm)

Argo CD follows the GitOps pattern of using Git repositories as the source of truth for defining the desired application state. 


Token and GitLab repository URL for ArgoCD to access to GitLab repository is stored in ./values/argocd.yaml encrypted by **Helm Secrets/SOPS**. 
Pls ask **age** private key (**key.txt**) and public key to decrypt/encrypt value files with sensitive data. Upload **key.txt** to user home folder.

Pls run following commands in **DevOps** instance:
1. **git clone git@gitlab.praktikum-services.ru:std-010-065/momo-store.git**
2. **cd momo-store/infrastructure**
3. **yc managed-kubernetes cluster get-credentials k8s-momo-store-prod-cluster-1 --external**
4. **kubectl apply -f manifests/init** # to create namespaces momo-app and argocd and 
5. **echo 'export SOPS_AGE_KEY_FILE=~/key.txt' >> ~/.bashrc**
6. **echo 'export SOPS_AGE_RECIPIENTS=age public key' >> ~/.bashrc**
7. **source ~/.bashrc**
8. **kubectl -n argocd create secret generic helm-secrets-private-keys --from-file=~/key.txt**

Decrypt encrypted value files with ingress annotations to be replaced with new values.

9. **helm secrets dec values/argocd.yaml**
10. **helm secrets dec values/momo-app.yaml**
11. **helm secrets dec values/momo-monitoring.yaml**

Replace values/argocd.yaml.dec, values/momo-app.yaml.dec, values/momo-monitoring.yaml files with updated values:
```
 secretName: yc-certmgr-cert-id-<id of cert-momo-store-prod-momo-voytenkov-ru>
 subnets: <id of subnet-momo-store-prod-a1>
 external_ipv4_address: <IP of ip-momo-store-prod-k8s-alb> 
 security_groups: <ID of sg-momo-store-prod-k8s-alb>,<ID of sg-momo-store-prod-k8s-main>
```

Encrypt value files.

9. **helm secrets enc values/argocd.yaml**
10. **helm secrets enc values/momo-app.yaml**
11. **helm secrets enc values/momo-monitoring.yaml**
12. **helm secrets clean .** # to delete decrypted files with sensitive data
13. **cd ..**
14. **git add .**
15. **git commit -m "ingress annotations updated"**
16. **git push**
17. **helm secrets install -n argocd argocd charts/argo-cd -f values/argocd.yaml**
18. **kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo** # to get ArgoCD Admin user password
19. **kubectl port-forward svc/argocd-server -n argocd 8080:443** # to temporary get access to ArgoCD web-interface via http://localhost:8080


###  Deploy Argocd App of Apps (Auto)

**App of Apps** will be used to deploy other Kubernetes applications via child subcharts, initial deployment and upgrades will be started automatically by ArgoCD after child applicatios charts pushed or changes commited to GitLab repository.
Pls see [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) for details.

**App of Apps** will be automatically deployed in Kubernetes with custom Argo CD Helm chart.

![Reference](./images/app-of-apps.jpg)

###  Deploy App of Apps Child Applications (Auto)

Following applications will be automatically deployed in Kubernetes by **App of Apps** as references to their charts and values are stated in **App of Apps** configuration files:

1. Momo App:
  - Backend
  - Frontend
2. Momo Monitoring:
  - Alertmanager
  - Grafana
  - Prometheus
  - Prometheus-Nginx-Exporter
3. YC ALB Ingress Controller

###  Switch on Ingress in ArgoCD (Helm)

Nevertheless ingress is configured in ArgoCD values, you need to apply values/argocd.yaml once again, because Ingress Controller has been deployed after initial installation of ArgoCD helm chart:

Pls check that YC ALB ingress controller has been installed and run following commands in **DevOps** instance:
1. **helm secrets install -n argocd argocd charts/argo-cd -f values/argocd.yaml**

###  Web-access to Deployed Applications

Momo Store application: [https://store.momo.voytenkov.ru](https://store.momo.voytenkov.ru)

ArgoCD: [https://argocd.momo.voytenkov.ru](https://argocd.momo.voytenkov.ru)

Alertmanager: [https://alertmanager.momo.voytenkov.ru](https://alertmanager.momo.voytenkov.ru)

Grafana: [https://grafana.momo.voytenkov.ru](https://grafana.momo.voytenkov.ru)

Prometheus: [https://prometheus.momo.voytenkov.ru](https://prometheus.momo.voytenkov.ru)


###  Momo Store Application Monitoring

Pls use Grafana dashbords for Nginx web-server monitoring used by Momo Store application. Initial password for Admin user is admin.

![Reference](./images/grafana.jpg)

