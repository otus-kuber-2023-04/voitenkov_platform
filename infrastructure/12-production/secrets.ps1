$ErrorActionPreference = 'silentlycontinue'

# Set static keys for access to TS state S3 storage
$Env:AWS_ACCESS_KEY_ID      = "YCAJE8znCb8KNTi-DRZhQv9v3"
$Env:AWS_SECRET_ACCESS_KEY  = "YCMm8jPWk_bCqf-5IkTU185wF-C9Rg5xyAeMoJT3"
[Environment]::SetEnvironmentVariable('AWS_ACCESS_KEY_ID', $Env:AWS_ACCESS_KEY_ID, 'User')
[Environment]::SetEnvironmentVariable('AWS_SECRET_ACCESS_KEY', $Env:AWS_SECRET_ACCESS_KEY, 'User')
