module "dev-folder" {
    source             = "../modules/folder"
    folder_project     = "momo-store"
    folder_environment = "dev" 
} 

module "prod-folder" {
    source             = "../modules/folder"
    folder_project     = "momo-store"
    folder_environment = "prod" 
} 