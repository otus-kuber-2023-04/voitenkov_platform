$ErrorActionPreference = 'silentlycontinue'

if ($(yc config profile get otus-kuber)) {
   
   # Activate YC CLI profile for otus-kuber cloud (if exists) 
   yc config profile activate otus-kuber
   $Env:TF_VAR_token     = $(yc config get token)
   $Env:TF_VAR_cloud_id  = $(yc config get cloud-id)
   $Env:TF_VAR_folder_id = ""

} 
else {

   # Activate otus-kuber-organization YC CLI profile of Yandex Cloud Organization to get current OAuth-token
   yc config profile activate organization
   $Env:TF_VAR_token     = $(yc config get token)

   # Create new YC CLI profile for otus-kuber cloud 
   yc config profile create otus-kuber
   yc config set token $Env:TF_VAR_token
   $cloud = $(yc resource-manager cloud get otus-kuber --format json) | ConvertFrom-Json
   $Env:TF_VAR_cloud_id = $cloud.id
   yc config set cloud-id $Env:TF_VAR_cloud_id
   $Env:TF_VAR_folder_id = ""

} 

# Set Environment Variables in User profile
[Environment]::SetEnvironmentVariable('TF_VAR_token', $Env:TF_VAR_token, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_cloud_id', $Env:TF_VAR_cloud_id, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_folder_id', $null, 'User')

# Get new IAM-token for requests to YC API 
$Env:TF_VAR_iam_token = $(yc iam create-token)
[Environment]::SetEnvironmentVariable('TF_VAR_iam_token', $Env:TF_VAR_iam_token, 'User')

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.ps1! ***********"