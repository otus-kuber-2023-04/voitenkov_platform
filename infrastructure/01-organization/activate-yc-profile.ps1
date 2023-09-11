$ErrorActionPreference = 'silentlycontinue'

if ($(yc config profile get organization)) {
   
   # Activate YC CLI profile (if exists) 
   yc config profile activate organization
   $Env:TF_VAR_token     = $(yc config get token)
   $Env:TF_VAR_cloud_id  = $(yc config get cloud-id)
   $Env:TF_VAR_folder_id = $(yc config get folder-id)

} 
else {

   # Activate default YC CLI profile of Yandex Cloud Organization to get current OAuth-token, cloud-id and folder-id
   yc config profile activate default
   $Env:TF_VAR_token     = $(yc config get token)
   $Env:TF_VAR_cloud_id  = $(yc config get cloud-id)
   $Env:TF_VAR_folder_id = $(yc config get folder-id)

   # Create new YC CLI profile for Yandex Cloud Organization
   yc config profile create organization
   yc config set token $Env:TF_VAR_token
   yc config set cloud-id $Env:TF_VAR_cloud_id
   yc config set folder-id $Env:TF_VAR_folder_id

} 

# Set Environment Variables in User profile
[Environment]::SetEnvironmentVariable('TF_VAR_token', $Env:TF_VAR_token, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_cloud_id', $Env:TF_VAR_cloud_id, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_folder_id', $Env:TF_VAR_folder_id, 'User')

# Get new IAM-token for requests to YC API 
$Env:TF_VAR_iam_token = $(yc iam create-token)
[Environment]::SetEnvironmentVariable('TF_VAR_iam_token', $Env:TF_VAR_iam_token, 'User')

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.ps1! ***********"





