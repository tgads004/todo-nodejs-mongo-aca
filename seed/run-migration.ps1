# run-migration.ps1
# Resolves the Cosmos endpoint from azd and runs the DMT migration locally.
# Prerequisites:
#   - dotnet tool install -g dmt
#   - az login (for RBAC auth against Azure Cosmos)
#   - Cosmos emulator running at https://localhost:8081 with seed data
#   - azd env is set up (azd up has been run)

$ErrorActionPreference = "Stop"

# 1. Get the endpoint
$endpoint = azd env get-value AZURE_COSMOS_ENDPOINT
if ([string]::IsNullOrEmpty($endpoint)) {
    Write-Error "AZURE_COSMOS_ENDPOINT not found. Run 'azd up' first."
    exit 1
}
Write-Host "Using Cosmos endpoint: $endpoint"

# 2. Write resolved settings to a temp file (never modify the source file)
$srcJson      = "$PSScriptRoot/migrationsettings.json"
$resolvedJson = "$env:TEMP/migrationsettings-resolved.json"
(Get-Content $srcJson -Raw) -replace "__COSMOS_ENDPOINT__", $endpoint | Set-Content $resolvedJson
Write-Host "Resolved settings written to: $resolvedJson"

# 3. Run the migration
# DMT is not on NuGet — locate the extracted executable
$dmtExe = "C:\tools\dmt\dmt.exe"
if (-not (Test-Path $dmtExe)) {
    Write-Error "dmt.exe not found at $dmtExe. Download from: https://github.com/AzureCosmosDB/data-migration-desktop-tool/releases"
    exit 1
}
Write-Host "Starting migration..."
& $dmtExe run --settings $resolvedJson
