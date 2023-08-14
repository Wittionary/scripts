$ConfigFile = ".\accelo.json"
Test-Path $ConfigFile
$Creds = Get-Content $ConfigFile | ConvertFrom-Json

$Deployment = "provisionsgroup"
$AuthURI = "https://$Deployment.api.accelo.com/oauth2/v0"
$BaseURI = "https://$Deployment.api.accelo.com/api/v0"

$Resource = "$BaseURI/staff"