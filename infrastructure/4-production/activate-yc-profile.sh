#!/bin/bash

if $(yc config profile get momo-prod); then 
   
   # Activate YC CLI profile for sa-momo-store-prod-tf service account (if exists) 
   yc config profile activate momo-prod
   export TF_VAR_cloud_id=$(yc config get cloud-id)
   export TF_VAR_folder_id=$(yc config get folder-id)

else 

   # Create new YC CLI profile for sa-momo-store-prod-tf service account
   yc config profile activate momo-cloud
   export TF_VAR_cloud_id=$(echo $(yc resource-manager cloud get momo-store --format json)|jq -r '.id')
   export TF_VAR_folder_id=$(echo $(yc resource-manager folder get prod-folder --format json)|jq -r '.id')
      
   yc iam key create --service-account-name sa-momo-store-prod-tf --folder-name prod-folder --output .\secrets\key.json
   yc config profile create momo-prod
   yc config set service-account-key .\secrets\key.json
   yc config set cloud-id $TF_VAR_cloud_id
   yc config set folder-id $TF_VAR_folder_id
     
fi

unset TF_VAR_token
export TF_VAR_zone="ru-central1-a"

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.sh! ***********"






