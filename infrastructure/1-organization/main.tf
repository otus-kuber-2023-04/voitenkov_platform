module "organization" {
    source                     = "../modules/cloud"
    cloud_project              = "organization"
    cloud_organization_id      = "bpf3hl81iopln542g8co"
    cloud_billing_account_id   = "dn2vvetl4d9ftp8ljtsa"
}

module "momo-cloud" {
    source                     = "../modules/cloud"
    cloud_project              = "momo-store"
    cloud_organization_id      = "bpf3hl81iopln542g8co"
    cloud_billing_account_id   = "dn2vvetl4d9ftp8ljtsa"
} 