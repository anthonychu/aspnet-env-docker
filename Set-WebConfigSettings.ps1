param (
    [string]$webConfig = "c:\inetpub\wwwroot\Web.config",
    [string]$secretsPath = $null
)

## Apply web.config transform if exists

$transformFile = "c:\web-config-transform\transform.config";

if (Test-Path $transformFile) {
    Write-Host "Running web.config transform..."
    \WebConfigTransformRunner.1.0.0.1\Tools\WebConfigTransformRunner.exe $webConfig $transformFile $webConfig
    Write-Host "Done!"
}


## Override app settings and connection string with environment variables

$doc = (Get-Content $webConfig) -as [Xml];
$modified = $FALSE;

$appSettingPrefix = "APPSETTING_";
$connectionStringPrefix = "CONNSTR_";

function UpdateAppSettingIfMatches([string]$key, [string]$value) {
    $appSetting = $doc.configuration.appSettings.add | Where-Object {$_.key -eq $key};
    if ($appSetting) {
        $appSetting.value = $value;
        Write-Host "Replaced appSetting" $key $value;
        $script:modified = $TRUE;
    }
}
function UpdateConnectionStringIfMatches([string]$key, [string]$value) {
    $connStr = $doc.configuration.connectionStrings.add | Where-Object {$_.name -eq $key};
    if ($connStr) {
        $connStr.connectionString = $value;
        Write-Host "Replaced connectionString" $key $value;
        $script:modified = $TRUE;
    }
}

Get-ChildItem "env:$($appSettingPrefix)*" | ForEach-Object {
    $key = $_.Key.Substring($appSettingPrefix.Length);
    $value = $_.Value;
    UpdateAppSettingIfMatches $key $value
}
Get-ChildItem "env:$($connectionStringPrefix)*" | ForEach-Object {
    $key = $_.Key.Substring($connectionStringPrefix.Length);
    $value = $_.Value;
    UpdateConnectionStringIfMatches $key $value
}

if ((-not [string]::IsNullOrEmpty($secretsPath)) `
        -and (Test-Path $secretsPath)) {
    Get-ChildItem "$secretsPath\$($appSettingPrefix)*" | ForEach-Object {
        $key = $_.Name.Substring($appSettingPrefix.Length);
        $value = Get-Content $_.FullName
        UpdateAppSettingIfMatches $key $value
    }
    Get-ChildItem "$secretsPath\$($connectionStringPrefix)*" | ForEach-Object {
        $key = $_.Name.Substring($connectionStringPrefix.Length);
        $value = Get-Content $_.FullName
        UpdateConnectionStringIfMatches $key $value
    }
}

if ($modified) {
    $doc.Save($webConfig);
}
