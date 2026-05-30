# Test Package Change Alert Hook
# Verifies the package-change-alert.ps1 hook correctly detects package.json changes
# and outputs informational messages

$ErrorActionPreference = "Stop"

$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"
$hookScript = "$proj\.github\hooks\scripts\package-change-alert.ps1"

$passCount = 0
$failCount = 0

function Test-HookScenario {
    param(
        [string]$Name,
        [string]$JsonInput,
        [string]$ExpectedPattern,
        [bool]$ShouldHaveOutput = $true
    )
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "TEST: $Name" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Input JSON:" -ForegroundColor Yellow
    Write-Host $JsonInput
    Write-Host ""
    
    try {
        $output = $JsonInput | pwsh -NoProfile -ExecutionPolicy Bypass -File $hookScript 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        
        Write-Host "Hook Output:" -ForegroundColor Yellow
        if ($output.Trim() -eq "") {
            Write-Host "(empty)" -ForegroundColor Gray
        } else {
            Write-Host $output
        }
        Write-Host ""
        Write-Host "Exit Code: $exitCode" -ForegroundColor Yellow
        Write-Host ""
        
        # Verify exit code is always 0 (non-blocking)
        if ($exitCode -ne 0) {
            Write-Host "❌ FAIL: Hook should always exit with code 0 (non-blocking)" -ForegroundColor Red
            Write-Host "   Expected: 0" -ForegroundColor Red
            Write-Host "   Actual: $exitCode" -ForegroundColor Red
            $script:failCount++
            return
        }
        
        # Verify output expectations
        if ($ShouldHaveOutput) {
            if ($output.Trim() -eq "") {
                Write-Host "❌ FAIL: Expected output but got empty response" -ForegroundColor Red
                $script:failCount++
                return
            }
            
            if ($ExpectedPattern -and $output -notmatch $ExpectedPattern) {
                Write-Host "❌ FAIL: Output doesn't match expected pattern" -ForegroundColor Red
                Write-Host "   Expected pattern: $ExpectedPattern" -ForegroundColor Red
                $script:failCount++
                return
            }
            
            # Verify JSON structure
            try {
                $result = $output | ConvertFrom-Json
                if (-not $result.systemMessage) {
                    Write-Host "❌ FAIL: Output JSON missing 'systemMessage' field" -ForegroundColor Red
                    $script:failCount++
                    return
                }
            } catch {
                Write-Host "❌ FAIL: Output is not valid JSON" -ForegroundColor Red
                Write-Host "   Error: $_" -ForegroundColor Red
                $script:failCount++
                return
            }
        } else {
            if ($output.Trim() -ne "") {
                Write-Host "❌ FAIL: Expected no output but got response" -ForegroundColor Red
                $script:failCount++
                return
            }
        }
        
        Write-Host "✅ PASS" -ForegroundColor Green
        $script:passCount++
        
    } catch {
        Write-Host "❌ FAIL: Exception occurred" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        $script:failCount++
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║          Package Change Alert Hook Test Suite                 ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

# Test 1: API package.json change with replace_string_in_file
$apiPath = "d:/Projects/Test Automation/Playwright/agentic architecture/todo-nodejs-mongo-aca/src/api/package.json"
$apiPathEscaped = $apiPath -replace '\\', '\\\\'
$json1 = @"
{
    "tool": {
        "name": "replace_string_in_file",
        "parameters": {
            "filePath": "$apiPathEscaped",
            "oldString": "\"express\": \"^4.18.0\"",
            "newString": "\"express\": \"^4.19.0\""
        }
    }
}
"@
Test-HookScenario -Name "API package.json change (replace_string_in_file)" `
                  -JsonInput $json1 `
                  -ExpectedPattern "src/api/package.json" `
                  -ShouldHaveOutput $true

# Test 2: Web package.json change with replace_string_in_file
$webPath = "d:/Projects/Test Automation/Playwright/agentic architecture/todo-nodejs-mongo-aca/src/web/package.json"
$webPathEscaped = $webPath -replace '\\', '\\\\'
$json2 = @"
{
    "tool": {
        "name": "replace_string_in_file",
        "parameters": {
            "filePath": "$webPathEscaped",
            "oldString": "\"react\": \"^18.0.0\"",
            "newString": "\"react\": \"^18.2.0\""
        }
    }
}
"@
Test-HookScenario -Name "Web package.json change (replace_string_in_file)" `
                  -JsonInput $json2 `
                  -ExpectedPattern "src/web/package.json" `
                  -ShouldHaveOutput $true

# Test 3: Both API and Web package.json changes with multi_replace_string_in_file
$json3 = @"
{
    "tool": {
        "name": "multi_replace_string_in_file",
        "parameters": {
            "replacements": [
                {
                    "filePath": "$apiPathEscaped",
                    "oldString": "\"express\": \"^4.18.0\"",
                    "newString": "\"express\": \"^4.19.0\""
                },
                {
                    "filePath": "$webPathEscaped",
                    "oldString": "\"react\": \"^18.0.0\"",
                    "newString": "\"react\": \"^18.2.0\""
                }
            ]
        }
    }
}
"@
Test-HookScenario -Name "Both services package.json changes (multi_replace_string_in_file)" `
                  -JsonInput $json3 `
                  -ExpectedPattern "src/(api|web)/package.json" `
                  -ShouldHaveOutput $true

# Test 4: Non-package.json file (should have no output)
$otherPath = "d:/Projects/Test Automation/Playwright/agentic architecture/todo-nodejs-mongo-aca/src/api/src/app.ts"
$otherPathEscaped = $otherPath -replace '\\', '\\\\'
$json4 = @"
{
    "tool": {
        "name": "replace_string_in_file",
        "parameters": {
            "filePath": "$otherPathEscaped",
            "oldString": "const port = 3100",
            "newString": "const port = 3200"
        }
    }
}
"@
Test-HookScenario -Name "Non-package.json file (should be silent)" `
                  -JsonInput $json4 `
                  -ShouldHaveOutput $false

# Test 5: Root level package.json (should be silent)
$rootPath = "d:/Projects/Test Automation/Playwright/agentic architecture/todo-nodejs-mongo-aca/package.json"
$rootPathEscaped = $rootPath -replace '\\', '\\\\'
$json5 = @"
{
    "tool": {
        "name": "replace_string_in_file",
        "parameters": {
            "filePath": "$rootPathEscaped",
            "oldString": "\"name\": \"todo-app\"",
            "newString": "\"name\": \"todo-app-v2\""
        }
    }
}
"@
Test-HookScenario -Name "Root package.json (should be silent)" `
                  -JsonInput $json5 `
                  -ShouldHaveOutput $false

# Test 6: Non-file-edit tool (should be silent)
$json6 = @"
{
    "tool": {
        "name": "read_file",
        "parameters": {
            "filePath": "$apiPathEscaped"
        }
    }
}
"@
Test-HookScenario -Name "Non-edit tool (read_file should be silent)" `
                  -JsonInput $json6 `
                  -ShouldHaveOutput $false

# Test 7: Invalid JSON input (should exit gracefully)
$json7 = "not valid json at all"
Test-HookScenario -Name "Invalid JSON input (should exit gracefully)" `
                  -JsonInput $json7 `
                  -ShouldHaveOutput $false

# Test 8: Empty JSON input (should exit gracefully)
$json8 = ""
Test-HookScenario -Name "Empty input (should exit gracefully)" `
                  -JsonInput $json8 `
                  -ShouldHaveOutput $false

# Test 9: create_file tool with package.json
$json9 = @"
{
    "tool": {
        "name": "create_file",
        "parameters": {
            "filePath": "$apiPathEscaped",
            "content": "{\"name\": \"api\", \"version\": \"1.0.0\"}"
        }
    }
}
"@
Test-HookScenario -Name "create_file with package.json" `
                  -JsonInput $json9 `
                  -ExpectedPattern "src/api/package.json" `
                  -ShouldHaveOutput $true

# Test 10: Verify message contains npm install command
$json10 = @"
{
    "tool": {
        "name": "replace_string_in_file",
        "parameters": {
            "filePath": "$apiPathEscaped",
            "oldString": "test",
            "newString": "test"
        }
    }
}
"@
Test-HookScenario -Name "Verify message contains npm install instructions" `
                  -JsonInput $json10 `
                  -ExpectedPattern "npm install" `
                  -ShouldHaveOutput $true

# Test 11: Verify message contains azd restore instructions
Test-HookScenario -Name "Verify message contains azd restore instructions" `
                  -JsonInput $json10 `
                  -ExpectedPattern "azd restore" `
                  -ShouldHaveOutput $true

# Test 12: Verify message mentions restarting dev servers
Test-HookScenario -Name "Verify message mentions restarting dev servers" `
                  -JsonInput $json10 `
                  -ExpectedPattern "(restart|Stop and re-run)" `
                  -ShouldHaveOutput $true

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                       Test Summary                             ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Total Tests: $($passCount + $failCount)" -ForegroundColor Cyan
Write-Host "✅ Passed: $passCount" -ForegroundColor Green
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed. Please review the output above." -ForegroundColor Yellow
    exit 1
}
