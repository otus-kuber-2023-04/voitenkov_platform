#!/bin/bash

if $(yc config profile get organization); then 
   
   # Activate YC CLI profile (if exists) 
   yc config profile activate organization
   export TF_VAR_token=$(yc config get token)
   export TF_VAR_cloud_id=$(yc config get cloud-id)
   export TF_VAR_folder_id=$(yc config get folder-id)
 
else 

   # Activate default YC CLI profile of Yandex Cloud Organization to get current OAuth-token, cloud-id and folder-id
   yc config profile activate default
   export TF_VAR_token=$(yc config get token)
   export TF_VAR_cloud_id=$(yc config get cloud-id)
   export TF_VAR_folder_id=$(yc config get folder-id)

   # Create new YC CLI profile for Yandex Cloud Organization
   yc config profile create organization
   yc config set token $TF_VAR_token
   yc config set cloud-id $TF_VAR_cloud_id
   yc config set folder-id $TF_VAR_folder_id

fi

# Get new IAM-token for requests to YC API 
export TF_VAR_iam_token=$(yc iam create-token)

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.sh! ***********"
