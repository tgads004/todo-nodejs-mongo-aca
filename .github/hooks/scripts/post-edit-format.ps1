#!/usr/bin/env pwsh
# Post-edit auto-format hook
# Automatically formats and lints code after Copilot edits files

param()

# Read the hook input from stdin
$stdinContent = [Console]::In.ReadToEnd()
$hookData = $stdinContent | ConvertFrom-Json -ErrorAction SilentlyContinue

# Check if this is a file edit operation
$toolName = $hookData.tool.name
$editedFiles = @()

# Extract file paths from different edit tools
switch ($toolName) {
    "replace_string_in_file" {
        $filePath = $hookData.tool.parameters.filePath
        if ($filePath) {
            $editedFiles += $filePath
        }
    }
    "multi_replace_string_in_file" {
        $replacements = $hookData.tool.parameters.replacements
        foreach ($replacement in $replacements) {
            if ($replacement.filePath) {
                $editedFiles += $replacement.filePath
            }
        }
    }
    "create_file" {
        $filePath = $hookData.tool.parameters.filePath
        if ($filePath) {
            $editedFiles += $filePath
        }
    }
    default {
        # Not a file edit operation, allow and exit
        $output = @{
            hookSpecificOutput = @{
                hookEventName = "PostToolUse"
                permissionDecision = "allow"
            }
        } | ConvertTo-Json -Depth 10
        Write-Output $output
        exit 0
    }
}

# Filter for TypeScript files in src/
$tsFilesToFormat = $editedFiles | Where-Object {
    $_ -match "src/.*\.(ts|tsx)$" -and (Test-Path $_)
} | Select-Object -Unique

if ($tsFilesToFormat.Count -eq 0) {
    # No TypeScript files to format, exit
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PostToolUse"
            permissionDecision = "allow"
        }
    } | ConvertTo-Json -Depth 10
    Write-Output $output
    exit 0
}

Write-Host "🎨 Auto-formatting edited files..." -ForegroundColor Cyan

$formatted = @()
$lintIssues = @()

foreach ($file in $tsFilesToFormat) {
    Write-Host "  Formatting: $file" -ForegroundColor Gray
    
    # Determine service directory (api or web)
    $service = $null
    if ($file -match "src[\\/]api[\\/]") {
        $service = "src/api"
    } elseif ($file -match "src[\\/]web[\\/]") {
        $service = "src/web"
    }
    
    if (-not $service) {
        Write-Host "    ⚠️  Skipped (not in api or web service)" -ForegroundColor Yellow
        continue
    }
    
    # Get relative path from service root for lint command
    $relativePath = $file -replace ".*[\\/]$service[\\/]", ""
    
    # Run lint --fix on the specific file
    try {
        Push-Location $service
        $lintResult = npm run lint -- --fix $relativePath 2>&1
        $lintExitCode = $LASTEXITCODE
        Pop-Location
        
        if ($lintExitCode -eq 0) {
            $formatted += $file
            Write-Host "    ✅ Formatted successfully" -ForegroundColor Green
        } else {
            # Lint found unfixable issues
            $unfixableIssues = ($lintResult | Select-String -Pattern "error|warning" | Select-Object -First 3) -join "`n      "
            if ($unfixableIssues) {
                $lintIssues += @{
                    file = $file
                    issues = $unfixableIssues
                }
                Write-Host "    ⚠️  Unfixable issues found" -ForegroundColor Yellow
            } else {
                # No output but non-zero exit - might be OK
                $formatted += $file
                Write-Host "    ✅ Processed" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "    ❌ Format failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Report results
Write-Host ""
if ($formatted.Count -gt 0) {
    Write-Host "✅ Auto-formatted $($formatted.Count) file(s)" -ForegroundColor Green
}

if ($lintIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Some files have unfixable lint issues:" -ForegroundColor Yellow
    foreach ($issue in $lintIssues) {
        Write-Host "  $($issue.file)" -ForegroundColor Yellow
        Write-Host "    $($issue.issues)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  Run lint manually to see full errors:" -ForegroundColor Cyan
    Write-Host "    cd src/api && npm run lint" -ForegroundColor Gray
    Write-Host "    cd src/web && npm run lint" -ForegroundColor Gray
}

Write-Host ""

# Always allow (post-operation hook)
$output = @{
    hookSpecificOutput = @{
        hookEventName = "PostToolUse"
        permissionDecision = "allow"
    }
} | ConvertTo-Json -Depth 10

Write-Output $output
exit 0
