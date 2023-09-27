$ErrorActionPreference = 'silentlycontinue'

# Set static keys for access to TS state S3 storage
$Env:AWS_ACCESS_KEY_ID      = "YCAJEkpWT5qs9JKdlWY52pbl3"
$Env:AWS_SECRET_ACCESS_KEY  = "YCPMK8G0UmQ6rIK_7GmOJUggSDqH0pyDZysrZAIX"
[Environment]::SetEnvironmentVariable('AWS_ACCESS_KEY_ID', $Env:AWS_ACCESS_KEY_ID, 'User')
[Environment]::SetEnvironmentVariable('AWS_SECRET_ACCESS_KEY', $Env:AWS_SECRET_ACCESS_KEY, 'User')
