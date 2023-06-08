#!/bin/bash

if $(yc config profile get momo-cloud); then 
   
   # Activate YC CLI profile for momo-store cloud (if exists) 
   yc config profile activate momo-cloud
   export TF_VAR_token=$(yc config get token)
   export TF_VAR_cloud_id=$(yc config get cloud-id)
   unset TF_VAR_folder_id
 
else 

   # Activate momo-organization YC CLI profile of Yandex Cloud Organization to get current OAuth-token
   yc config profile activate momo-organization
   export TF_VAR_token=$(yc config get token)
   
   # Create new YC CLI profile for momo-store cloud 
   yc config profile create momo-cloud
   yc config set token $TF_VAR_token
   
   export TF_VAR_cloud_id=$(echo $(yc resource-manager cloud get momo-store --format json)|jq -r '.id')
   yc config set cloud-id $TF_VAR_cloud_id
   unset TF_VAR_folder_id
   
fi

# Get new IAM-token for requests to YC API 
export TF_VAR_iam_token=$(yc iam create-token)

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.sh! ***********"




