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

Get-ChildItem "env:*~*" | ForEach-Object {
    # Find and replace xpath
    # Pass an encoded xpath and attribute to set =>  UrlEncode(<xpath>~<attr>) = VALUE
    if ($_.Key.IndexOf('~') -gt 0) {
        Add-Type -AssemblyName System.Web
        $key = [System.Web.HttpUtility]::UrlDecode($_.key)
        $index = $key.IndexOf('~')
        $xpath = $key.substring(0, $index);
        $attr = $key.substring($index + 1);
        $doc.SelectSingleNode($xpath).SetAttribute($attr, $_.Value);
        Write-Host "Replaced xPath" $xpath $_.Value;
        $script:modified = $TRUE;
    }
}

if ($modified) {
    $doc.Save($webConfig);
}
