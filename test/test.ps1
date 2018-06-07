$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$testRunPath = "$here\test-run\"

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
    $env:APPSETTING_NewValue = "Wibble" # shouldn't see this as values are only overridden, not added

    $env:CONNSTR_DefaultConnection = "NewValue!"
    $env:CONNSTR_NewConnection = "Testing here" # shouldn't see this as values are only overridden, not added
}
function ApplyToWebConfig() {
    Write-Host "Applying web.config changes..."
    &"$here\..\Set-WebConfigSettings.ps1" -webConfig "$testRunPath\web.config"  | out-null
}
function CompareResult() {
    Compare-Object `
        -ReferenceObject (Get-Content "$here\test_files\expected-web.config") `
        -DifferenceObject (Get-Content "$testRunPath\web.config")
}

EnsureCleanTestRunDirectory
SetTestEnvironmentVariables
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