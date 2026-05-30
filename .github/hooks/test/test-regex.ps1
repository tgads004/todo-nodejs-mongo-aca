# Test regex pattern matching

$testPath = "d:\\Projects\\Test Automation\\Playwright\\agentic architecture\\todo-nodejs-mongo-aca\\src\\test-temp-debug2\\api\\src\\routes\\lists.ts"

Write-Host "Test Path:" -ForegroundColor Cyan
Write-Host $testPath
Write-Host ""

Write-Host "Character breakdown:" -ForegroundColor Yellow
for ($i = 0; $i -lt $testPath.Length; $i++) {
    $char = $testPath[$i]
    if ($char -eq '\') {
        Write-Host "Position $i : BACKSLASH"
    }
}
Write-Host ""

$pattern1 = "[/\\]api[/\\]src[/\\]routes[/\\][^/\\]+\.ts$"
Write-Host "Pattern 1: $pattern1" -ForegroundColor Yellow
Write-Host "Match: $($testPath -match $pattern1)" -ForegroundColor $(if ($testPath -match $pattern1) { "Green" } else { "Red" })
Write-Host ""

$pattern2 = "\\api\\src\\routes\\"
Write-Host "Pattern 2: $pattern2" -ForegroundColor Yellow  
Write-Host "Match: $($testPath -match $pattern2)" -ForegroundColor $(if ($testPath -match $pattern2) { "Green" } else { "Red" })
Write-Host ""

$pattern3 = "api"
Write-Host "Pattern 3: $pattern3" -ForegroundColor Yellow
Write-Host "Match: $($testPath -match $pattern3)" -ForegroundColor $(if ($testPath -match $pattern3) { "Green" } else { "Red" })
