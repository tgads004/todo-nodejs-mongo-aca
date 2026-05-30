# Package Change Alert Hook - Reminds to install dependencies after package.json changes
# Runs on PostToolUse after editing package.json files
# Non-blocking informational message only

$ErrorActionPreference = "SilentlyContinue"

# Read hook input from stdin
$stdinContent = [Console]::In.ReadToEnd()

# Attempt to parse JSON - suppress all errors
try {
    $hookData = $stdinContent | ConvertFrom-Json -ErrorAction SilentlyContinue
} catch {
    # Parsing failed - exit silently (non-blocking)
    exit 0
}

if (-not $hookData) {
    # No valid JSON input - exit silently
    exit 0
}

# Only process file modification tools
$toolName = $hookData.tool.name
if ($toolName -notin @("create_file", "replace_string_in_file", "multi_replace_string_in_file")) {
    # Not a file edit - exit silently
    exit 0
}

# Extract file path(s) from tool parameters
$filePaths = @()
if ($toolName -eq "multi_replace_string_in_file") {
    $filePaths = $hookData.tool.parameters.replacements | ForEach-Object { $_.filePath }
} else {
    $filePaths = @($hookData.tool.parameters.filePath)
}

# Filter for package.json files in src/api/ or src/web/
$packageJsonFiles = $filePaths | Where-Object {
    $_ -match "[/\\]src[/\\](api|web)[/\\]package\.json$"
}

if ($packageJsonFiles.Count -eq 0) {
    # No package.json files edited - exit silently
    exit 0
}

# Determine which services were affected
$affectedServices = @()
$apiChanged = $packageJsonFiles | Where-Object { $_ -match "[/\\]api[/\\]" }
$webChanged = $packageJsonFiles | Where-Object { $_ -match "[/\\]web[/\\]" }

if ($apiChanged) {
    $affectedServices += "api"
}
if ($webChanged) {
    $affectedServices += "web"
}

# Build informational message
$message = "📦 PACKAGE.JSON CHANGED — Dependencies may need updating`r`n"
$message += "Changes have been saved.`r`n`r`n"

foreach ($service in $affectedServices) {
    $relPath = "src/$service/package.json"
    $message += "📄 $relPath modified`r`n"
}

$message += "`r`n💡 Don't forget to install dependencies:`r`n"

foreach ($service in $affectedServices) {
    $message += "   cd src/$service && npm install`r`n"
}

$message += "`r`nOr use the Azure Developer CLI to restore all services:`r`n"
$message += "   azd restore`r`n"
$message += "`r`n⚠️  If dev servers are running, restart them to pick up new dependencies:`r`n"

if ($affectedServices -contains "api") {
    $message += "   • API: Stop and re-run 'Start API' task or npm run start`r`n"
}
if ($affectedServices -contains "web") {
    $message += "   • Web: Stop and re-run 'Start Web' task or npm run dev`r`n"
}

$message += "`r`n🤖 Would you like me to run the install commands for you?"

# Output hook result
$result = @{
    hookSpecificOutput = @{
        hookEventName = "PostToolUse"
    }
    systemMessage = $message
} | ConvertTo-Json -Depth 5 -Compress

Write-Output $result

# Always exit 0 (non-blocking informational message)
exit 0
