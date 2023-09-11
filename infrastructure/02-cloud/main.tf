module "dev-folder" {
    source             = "../modules/folder"
    folder_project     = "otus-kuber"
    folder_environment = "dev" 
} 

module "prod-folder" {
    source             = "../modules/folder"
    folder_project     = "otus-kuber"
    folder_environment = "prod" 
} 

module "stage-folder" {
    source             = "../modules/folder"
    folder_project     = "otus-kuber"
    folder_environment = "stage" 
} 

module "test-folder" {
    source             = "../modules/folder"
    folder_project     = "otus-kuber"
    folder_environment = "test" 
} 