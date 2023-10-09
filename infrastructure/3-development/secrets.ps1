$ErrorActionPreference = 'silentlycontinue'

# Set static keys for access to TS state S3 storage
$Env:AWS_ACCESS_KEY_ID      = "YCAJE0ESwQ_wFtb7cEz20ysMJ"
$Env:AWS_SECRET_ACCESS_KEY  = "YCOOps-VqQsTcQLEDtrEP8LfNEO6OYosLFVQo9oI"
[Environment]::SetEnvironmentVariable('AWS_ACCESS_KEY_ID', $Env:AWS_ACCESS_KEY_ID, 'User')
[Environment]::SetEnvironmentVariable('AWS_SECRET_ACCESS_KEY', $Env:AWS_SECRET_ACCESS_KEY, 'User')
