# Pull secrets path from ASPNET_SECRETS_PATH (and default to c:\secrets)
$secretsPath = $env:ASPNET_SECRETS_PATH
if ($secretsPath -eq $null){
    $secretsPath = "c:\secrets" 
}
C:\aspnet-startup\Set-WebConfigSettings.ps1 -webConfig c:\inetpub\wwwroot\Web.config -secretsPath $secretsPath
C:\ServiceMonitor.exe w3svc