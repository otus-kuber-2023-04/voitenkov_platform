$ErrorActionPreference = 'silentlycontinue'

if ($(yc config profile get otus-kuber-test)) {
   
   # Activate YC CLI profile for sa-otus-kuber-test-tf service account (if exists) 
   yc config profile activate otus-kuber-test
   $Env:TF_VAR_cloud_id  = $(yc config get cloud-id)
   $Env:TF_VAR_folder_id = $(yc config get folder-id)

} 
else {

   # Create new YC CLI profile for sa-otus-kuber-test-tf service account
   yc config profile activate momo-cloud
   $cloud                = $(yc resource-manager cloud get otus-kuber --format json) | ConvertFrom-Json
   $Env:TF_VAR_cloud_id  = $cloud.id
   $folder               = $(yc resource-manager folder get test-folder --format json) | ConvertFrom-Json
   $Env:TF_VAR_folder_id = $folder.id
  
   yc iam key create --service-account-name sa-otus-kuber-test-tf --folder-name test-folder --output .\secrets\key.json
   yc config profile create otus-kuber-test
   yc config set service-account-key .\secrets\key.json
   yc config set cloud-id $Env:TF_VAR_cloud_id
   yc config set folder-id $Env:TF_VAR_folder_id
 
} 

$Env:TF_VAR_token = ""
$Env:TF_VAR_zone  = "ru-central1-a"

# Set Environment Variables in User profile
[Environment]::SetEnvironmentVariable('TF_VAR_token', $null, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_cloud_id', $Env:TF_VAR_cloud_id, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_folder_id', $Env:TF_VAR_folder_id, 'User')
[Environment]::SetEnvironmentVariable('TF_VAR_zone', $Env:TF_VAR_zone, 'User')

# Set static keys for access to TS state S3 storage
echo ""
echo "************* Pls don't forget to run separate secrets.ps1! ***********"