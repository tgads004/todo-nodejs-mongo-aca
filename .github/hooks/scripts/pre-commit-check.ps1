#!/usr/bin/env pwsh
# Pre-commit quality gate hook
# Enforces standards from AGENTS.md before allowing git commits

param()

# Read the hook input from stdin
$stdinContent = [Console]::In.ReadToEnd()
$hookData = $stdinContent | ConvertFrom-Json -ErrorAction SilentlyContinue

# Check if this is a git commit operation
$toolName = $hookData.tool.name
$command = $hookData.tool.parameters.command

$isGitCommit = $false
if ($toolName -eq "run_in_terminal" -and $command) {
    # Check for git commit commands
    if ($command -match "git\s+commit" -and $command -notmatch "--no-verify") {
        $isGitCommit = $true
    }
}

# If not a git commit, allow it
if (-not $isGitCommit) {
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "allow"
        }
    } | ConvertTo-Json -Depth 10
    Write-Output $output
    exit 0
}

# Run quality checks
Write-Host "🔍 Running pre-commit quality checks..." -ForegroundColor Cyan

$failures = @()
$warnings = @()

# Check 1: TypeScript compilation (API)
Write-Host "  Checking TypeScript compilation (API)..." -ForegroundColor Gray
Push-Location "src/api"
$buildResult = npm run build 2>&1
$buildExitCode = $LASTEXITCODE
Pop-Location

if ($buildExitCode -ne 0) {
    $failures += @{
        check = "TypeScript compilation (API)"
        message = "Build failed in src/api"
        output = ($buildResult | Select-Object -Last 10) -join "`n"
        fix = "cd src/api && npm run build"
    }
}

# Check 2: TypeScript compilation (Web)
Write-Host "  Checking TypeScript compilation (Web)..." -ForegroundColor Gray
Push-Location "src/web"
$buildResult = npm run build 2>&1
$buildExitCode = $LASTEXITCODE
Pop-Location

if ($buildExitCode -ne 0) {
    $failures += @{
        check = "TypeScript compilation (Web)"
        message = "Build failed in src/web"
        output = ($buildResult | Select-Object -Last 10) -join "`n"
        fix = "cd src/web && npm run build"
    }
}

# Check 3: Linting (API)
Write-Host "  Checking linting (API)..." -ForegroundColor Gray
Push-Location "src/api"
$lintResult = npm run lint 2>&1
$lintExitCode = $LASTEXITCODE
Pop-Location

if ($lintExitCode -ne 0) {
    $failures += @{
        check = "Linting (API)"
        message = "Lint failed in src/api - zero warnings required"
        output = ($lintResult | Select-Object -Last 10) -join "`n"
        fix = "cd src/api && npm run lint"
    }
}

# Check 4: Linting (Web)
Write-Host "  Checking linting (Web)..." -ForegroundColor Gray
Push-Location "src/web"
$lintResult = npm run lint 2>&1
$lintExitCode = $LASTEXITCODE
Pop-Location

if ($lintExitCode -ne 0) {
    $failures += @{
        check = "Linting (Web)"
        message = "Lint failed in src/web - zero warnings required"
        output = ($lintResult | Select-Object -Last 10) -join "`n"
        fix = "cd src/web && npm run lint"
    }
}

# Check 5: API Tests
Write-Host "  Running API tests..." -ForegroundColor Gray
Push-Location "src/api"
$testResult = npm test 2>&1
$testExitCode = $LASTEXITCODE
Pop-Location

if ($testExitCode -ne 0) {
    $failures += @{
        check = "API Tests"
        message = "Tests failed in src/api"
        output = ($testResult | Select-Object -Last 10) -join "`n"
        fix = "cd src/api && npm test"
    }
}

# Check 6: Secrets scan
Write-Host "  Scanning for hardcoded secrets..." -ForegroundColor Gray
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

$secretPatterns = @(
    "mongodb://",
    "mongodb+srv://",
    "AccountKey=",
    "DefaultEndpointsProtocol=",
    "password\s*=",
    "apiKey\s*=",
    "secret\s*=",
    "token\s*="
)

foreach ($file in $stagedFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content) {
            foreach ($pattern in $secretPatterns) {
                if ($content -match $pattern) {
                    # Skip if in .env or config files (expected locations)
                    if ($file -notmatch "\.env|config/default\.json|\.example") {
                        $failures += @{
                            check = "Secrets Scan"
                            message = "Potential secret found in $file"
                            output = "Pattern matched: $pattern"
                            fix = "Remove hardcoded secrets. Use environment variables via config module."
                        }
                    }
                }
            }
        }
    }
}

# Check 7: File naming conventions
Write-Host "  Checking file naming conventions..." -ForegroundColor Gray
foreach ($file in $stagedFiles) {
    # Check API route files (should be plural)
    if ($file -match "src/api/src/routes/(\w+)\.ts$") {
        $fileName = $matches[1]
        # Simple check: if file doesn't end in 's', might be wrong
        # (Crude heuristic - common.ts, routes.spec.ts are exceptions)
        if ($fileName -notmatch "s$" -and $fileName -ne "common" -and $fileName -notmatch "\.spec$") {
            $warnings += @{
                check = "File Naming"
                message = "Route file should use plural name: $file"
                fix = "Rename to plural form (e.g., items.ts, users.ts)"
                doc = "docs/api-standards.md"
            }
        }
    }
    
    # Check model files (should be singular)
    if ($file -match "src/api/src/models/(\w+)\.ts$") {
        $fileName = $matches[1]
        # Models like cosmos.ts, sampleData.ts are exceptions
        if ($fileName -match "s$" -and $fileName -ne "cosmos" -and $fileName -notmatch "Data$") {
            $warnings += @{
                check = "File Naming"
                message = "Model file should use singular name: $file"
                fix = "Rename to singular form (e.g., todoItem.ts, user.ts)"
                doc = "docs/api-standards.md"
            }
        }
    }
}

# Determine outcome
if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Pre-commit check FAILED!" -ForegroundColor Red
    Write-Host ""
    
    foreach ($failure in $failures) {
        Write-Host "  ❌ $($failure.check)" -ForegroundColor Red
        Write-Host "     $($failure.message)" -ForegroundColor Yellow
        if ($failure.output) {
            Write-Host "     $($failure.output)" -ForegroundColor Gray
        }
        Write-Host "     Fix: $($failure.fix)" -ForegroundColor Cyan
        if ($failure.doc) {
            Write-Host "     See: $($failure.doc)" -ForegroundColor Blue
        }
        Write-Host ""
    }
    
    Write-Host "To bypass this check (not recommended):" -ForegroundColor Gray
    Write-Host "  git commit --no-verify" -ForegroundColor Gray
    Write-Host ""
    
    # Block the commit
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = "$($failures.Count) quality check(s) failed. Fix issues or use --no-verify to bypass."
        }
        systemMessage = "❌ Pre-commit checks failed. See output above for details."
    } | ConvertTo-Json -Depth 10
    
    Write-Output $output
    exit 2
}

# Show warnings but allow commit
if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Pre-commit warnings (non-blocking):" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($warning in $warnings) {
        Write-Host "  ⚠️  $($warning.check)" -ForegroundColor Yellow
        Write-Host "     $($warning.message)" -ForegroundColor Gray
        Write-Host "     Fix: $($warning.fix)" -ForegroundColor Cyan
        if ($warning.doc) {
            Write-Host "     See: $($warning.doc)" -ForegroundColor Blue
        }
        Write-Host ""
    }
}

# All checks passed
Write-Host ""
Write-Host "✅ Pre-commit checks passed!" -ForegroundColor Green
Write-Host ""

$output = @{
    hookSpecificOutput = @{
        hookEventName = "PreToolUse"
        permissionDecision = "allow"
    }
} | ConvertTo-Json -Depth 10

Write-Output $output
exit 0
