# Debug version of test-coverage-check.ps1 with verbose output

$ErrorActionPreference = "Stop"

Write-Output "DEBUG: Starting hook" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

# Read hook input from stdin
$stdinContent = [Console]::In.ReadToEnd()
Write-Output "DEBUG: Read stdin: $stdinContent" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

try {
    $hookData = $stdinContent | ConvertFrom-Json -ErrorAction Stop
    Write-Output "DEBUG: Parsed JSON successfully" | Out-File -FilePath "c:\temp\hook-debug.log" -Append
} catch {
    Write-Output "DEBUG: JSON parse failed: $_" | Out-File -FilePath "c:\temp\hook-debug.log" -Append
    exit 0
}

if (-not $hookData) {
    Write-Output "DEBUG: No hookData" | Out-File -FilePath "c:\temp\hook-debug.log" -Append
    exit 0
}

# Only process file modification tools
$toolName = $hookData.tool.name
Write-Output "DEBUG: Tool name: $toolName" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

if ($toolName -notin @("create_file", "replace_string_in_file", "multi_replace_string_in_file")) {
    Write-Output "DEBUG: Tool not in list - exiting" | Out-File -FilePath "c:\temp\hook-debug.log" -Append
    exit 0
}

# Extract file path(s) from tool parameters
$filePaths = @()
if ($toolName -eq "multi_replace_string_in_file") {
    $filePaths = $hookData.tool.parameters.replacements | ForEach-Object { $_.filePath }
} else {
    $filePaths = @($hookData.tool.parameters.filePath)
}
Write-Output "DEBUG: File paths: $($filePaths -join ', ')" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

# Filter for API route files only (not spec files, not common.ts)
$routeFiles = $filePaths | Where-Object {
    $_ -match "[/\\]api[/\\]src[/\\]routes[/\\][^/\\]+\.ts$" -and
    $_ -notmatch "\.spec\.ts$" -and
    $_ -notmatch "[/\\]common\.ts$"
}
Write-Output "DEBUG: Route files: $($routeFiles -join ', ')" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

if ($routeFiles.Count -eq 0) {
    Write-Output "DEBUG: No route files - exiting" | Out-File -FilePath "c:\temp\hook-debug.log" -Append
    exit 0
}

Write-Output "DEBUG: Processing $($routeFiles.Count) route file(s)" | Out-File -FilePath "c:\temp\hook-debug.log" -Append

# Always exit 0 (non-blocking warning)
exit 0
