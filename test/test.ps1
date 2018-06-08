$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$testRunPath = "$here\test-run"
$secretBasePath = "$testRunPath\secrets"

function EnsureCleanTestRunDirectory() {
    Write-Host "Creating temp test run directory..."
    if (Test-Path $testRunPath) {
        Remove-Item -Path $testRunPath -Recurse -Force
    }
    New-Item -Path $testRunPath -ItemType Directory | out-null
    Set-Content -Path "$testRunPath\.gitignore" -Value "*" # avoid accidentally committing test execution junk

    Copy-Item "$here\test_files\initial-web.config" "$testRunPath\web.config" | out-null
}
function SetTestEnvironmentVariables() {
    Write-Host "Setting up environment variables..."
    $env:APPSETTING_PageTitle = "OverriddenValue"
    $env:APPSETTING_YetAnotherValue = "Shouldn't see this setting" # should be overridden by secret
    $env:APPSETTING_NewValue = "Wibble" # shouldn't see this as values are only overridden, not added

    $env:CONNSTR_DefaultConnection = "NewValue!"
    $env:CONNSTR_YetAnotherConnection = "Shouldn't see this connection string" # should be overridden by secret
    $env:CONNSTR_NewConnection = "Testing here" # shouldn't see this as values are only overridden, not added
}
function CreateTestSecrets() {
    New-Item -Path $secretBasePath -ItemType Directory | out-null

    Set-Content -Path "$secretBasePath\APPSETTING_AnotherValue" -Value "Secret Setting"
    Set-Content -Path "$secretBasePath\APPSETTING_YetAnotherValue" -Value "Another Secret Setting"

    Set-Content -Path "$secretBasePath\CONNSTR_AnotherConnection" -Value "Secret Value"
    Set-Content -Path "$secretBasePath\CONNSTR_YetAnotherConnection" -Value "Another Secret Value"
}
function ApplyToWebConfig() {
    Write-Host "Applying web.config changes..."
    &"$here\..\Set-WebConfigSettings.ps1" -webConfig "$testRunPath\web.config" -secretsPath $secretBasePath | out-null
}
function CompareResult() {
    Compare-Object `
        -ReferenceObject (Get-Content "$here\test_files\expected-web.config") `
        -DifferenceObject (Get-Content "$testRunPath\web.config")
}

EnsureCleanTestRunDirectory
SetTestEnvironmentVariables
CreateTestSecrets
ApplyToWebConfig
$differences = CompareResult
Write-Host
if ($differences -eq $null) {
    Write-Host "Files matched!"
    exit 0
}
Write-Host "Files differ!"
Write-Output $differences | Format-Table
exit 1