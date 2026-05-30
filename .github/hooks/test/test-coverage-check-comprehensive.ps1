# Comprehensive Test Suite for test-coverage-api Hook
# Tests various scenarios to ensure the hook detects missing tests correctly

$ErrorActionPreference = "Stop"

$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"
$hookScript = "$proj\.github\hooks\scripts\test-coverage-check.ps1"

# Helper function to run hook with JSON input
function Invoke-Hook {
    param([string]$JsonInput)
    
    $output = $JsonInput | pwsh -NoProfile -File $hookScript 2>&1 | Out-String
    return $output.Trim()
}

# Helper to create properly escaped JSON
function New-HookJson {
    param(
        [string]$ToolName,
        [string]$FilePath,
        [array]$Replacements = @()
    )
    
    if ($ToolName -eq "multi_replace_string_in_file") {
        $repsObjects = $Replacements | ForEach-Object {
            @{ filePath = $_ }
        }
        $hookData = @{
            tool = @{
                name = $ToolName
                parameters = @{
                    replacements = $repsObjects
                }
            }
        }
    } else {
        $hookData = @{
            tool = @{
                name = $ToolName
                parameters = @{
                    filePath = $FilePath
                }
            }
        }
    }
    
    return ($hookData | ConvertTo-Json -Depth 5 -Compress)
}

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  TEST SUITE: test-coverage-api Hook Comprehensive Tests   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

# ============================================================================
# TEST 1: Edit lists.ts - Should PASS (all routes have tests)
# ============================================================================
Write-Host "TEST 1: Edit lists.ts (all routes covered)" -ForegroundColor Yellow
Write-Host "Expected: No warnings (all routes have tests)`n" -ForegroundColor Gray

$json1 = New-HookJson -ToolName "replace_string_in_file" -FilePath "$proj\src\api\src\routes\lists.ts"
$result1 = Invoke-Hook -JsonInput $json1

if ($result1 -eq "") {
    Write-Host "✓ PASSED: No warnings detected (as expected)`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Unexpected warning detected" -ForegroundColor Red
    Write-Host "Output: $result1`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# TEST 2: Create temporary route file with uncovered route
# ============================================================================
Write-Host "TEST 2: Create route file with missing test" -ForegroundColor Yellow
Write-Host "Expected: Warning about missing test`n" -ForegroundColor Gray

$tempRouteDir = "$proj\src\test-temp-" + (Get-Random)
$tempRouteFile = "$tempRouteDir\api\src\routes\lists.ts"
$tempSpecFile = "$tempRouteDir\api\src\routes\routes.spec.ts"
New-Item -Path (Split-Path $tempRouteFile) -ItemType Directory -Force | Out-Null

# Create a route file with a new PATCH route (not in tests)
$tempContent = @'
import express from "express";
const router = express.Router();

// Existing routes (covered)
router.get("/", async (req, res) => { res.json([]); });
router.post("/", async (req, res) => { res.status(201).json({}); });

// NEW ROUTE - NOT COVERED BY TESTS
router.patch("/:listId/archive", async (req, res) => { res.json({}); });

export default router;
'@

# Create a spec file that only covers GET and POST, not PATCH
$tempSpecContent = @'
describe("Todo List Routes", () => {
    it("can GET an array of lists", async () => {
        // test GET
    });
    
    it("can POST (create) new list", async () => {
        // test POST
    });
});
'@

Set-Content -Path $tempRouteFile -Value $tempContent
Set-Content -Path $tempSpecFile -Value $tempSpecContent

$json2 = New-HookJson -ToolName "replace_string_in_file" -FilePath $tempRouteFile
$result2 = Invoke-Hook -JsonInput $json2

if ($result2 -match "TEST COVERAGE GAP" -and $result2 -match "PATCH") {
    Write-Host "✓ PASSED: Warning detected for missing PATCH test`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Expected warning not detected" -ForegroundColor Red
    Write-Host "Output: $result2`n" -ForegroundColor Red
    $testsFailed++
}

# Cleanup temp directory
Remove-Item -Path $tempRouteDir -Recurse -Force -ErrorAction SilentlyContinue

# ============================================================================
# TEST 3: multi_replace_string_in_file - Multiple files
# ============================================================================
Write-Host "TEST 3: Multi-file edit with multi_replace_string_in_file" -ForegroundColor Yellow
Write-Host "Expected: No warnings (both files covered)`n" -ForegroundColor Gray

$json3 = New-HookJson -ToolName "multi_replace_string_in_file" `
    -Replacements @("$proj\src\api\src\routes\lists.ts", "$proj\src\api\src\routes\items.ts")
$result3 = Invoke-Hook -JsonInput $json3

if ($result3 -eq "") {
    Write-Host "✓ PASSED: No warnings for multiple covered files`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Unexpected warning detected" -ForegroundColor Red
    Write-Host "Output: $result3`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# TEST 4: create_file tool
# ============================================================================
Write-Host "TEST 4: create_file tool on new route file" -ForegroundColor Yellow
Write-Host "Expected: Warning about missing tests`n" -ForegroundColor Gray

$tempDir2 = "$proj\src\test-temp-" + (Get-Random)
$tempFile2 = "$tempDir2\api\src\routes\lists.ts"
$tempSpec2 = "$tempDir2\api\src\routes\routes.spec.ts"
New-Item -Path (Split-Path $tempFile2) -ItemType Directory -Force | Out-Null

$tempContent2 = @'
import express from "express";
const router = express.Router();
router.get("/", async (req, res) => { res.json([]); });
router.post("/:id/clone", async (req, res) => { res.json({}); });
export default router;
'@

# Spec file that only covers GET, not POST /:id/clone
$tempSpec2Content = @'
describe("Todo List Routes", () => {
    it("can GET an array of lists", async () => {
        // test GET
    });
});
'@

Set-Content -Path $tempFile2 -Value $tempContent2
Set-Content -Path $tempSpec2 -Value $tempSpec2Content

$json4 = New-HookJson -ToolName "create_file" -FilePath $tempFile2
$result4 = Invoke-Hook -JsonInput $json4

if ($result4 -match "TEST COVERAGE GAP" -and $result4 -match "POST") {
    Write-Host "✓ PASSED: Warning detected for new file with missing tests`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Expected warning not detected" -ForegroundColor Red
    Write-Host "Output: $result4`n" -ForegroundColor Red
    $testsFailed++
}

# Cleanup
Remove-Item -Path $tempDir2 -Recurse -Force -ErrorAction SilentlyContinue

# ============================================================================
# TEST 5: Non-route file (should be ignored)
# ============================================================================
Write-Host "TEST 5: Edit non-route file (should be ignored)" -ForegroundColor Yellow
Write-Host "Expected: No output (file ignored)`n" -ForegroundColor Gray

$json5 = New-HookJson -ToolName "replace_string_in_file" -FilePath "$proj\src\api\src\models\todoList.ts"
$result5 = Invoke-Hook -JsonInput $json5

if ($result5 -eq "") {
    Write-Host "✓ PASSED: Non-route file correctly ignored`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Non-route file should be ignored" -ForegroundColor Red
    Write-Host "Output: $result5`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# TEST 6: Edit common.ts (should be ignored)
# ============================================================================
Write-Host "TEST 6: Edit common.ts (should be ignored)" -ForegroundColor Yellow
Write-Host "Expected: No output (common.ts excluded)`n" -ForegroundColor Gray

$json6 = New-HookJson -ToolName "replace_string_in_file" -FilePath "$proj\src\api\src\routes\common.ts"
$result6 = Invoke-Hook -JsonInput $json6

if ($result6 -eq "") {
    Write-Host "✓ PASSED: common.ts correctly ignored`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: common.ts should be ignored" -ForegroundColor Red
    Write-Host "Output: $result6`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# TEST 7: Invalid JSON input (should exit gracefully)
# ============================================================================
Write-Host "TEST 7: Invalid JSON input" -ForegroundColor Yellow
Write-Host "Expected: Silent exit (no error)`n" -ForegroundColor Gray

$json7 = "invalid json{{"
$result7 = Invoke-Hook -JsonInput $json7

if ($result7 -eq "") {
    Write-Host "✓ PASSED: Invalid JSON handled gracefully`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Should handle invalid JSON silently" -ForegroundColor Red
    Write-Host "Output: $result7`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# TEST 8: Edit routes.spec.ts (should be ignored)
# ============================================================================
Write-Host "TEST 8: Edit routes.spec.ts (should be ignored)" -ForegroundColor Yellow
Write-Host "Expected: No output (spec files excluded)`n" -ForegroundColor Gray

$json8 = New-HookJson -ToolName "replace_string_in_file" -FilePath "$proj\src\api\src\routes\routes.spec.ts"
$result8 = Invoke-Hook -JsonInput $json8

if ($result8 -eq "") {
    Write-Host "✓ PASSED: Spec file correctly ignored`n" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ FAILED: Spec file should be ignored" -ForegroundColor Red
    Write-Host "Output: $result8`n" -ForegroundColor Red
    $testsFailed++
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      TEST SUMMARY                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$total = $testsPassed + $testsFailed
Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed:      $testsPassed" -ForegroundColor Green
Write-Host "Failed:      $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -eq 0) {
    Write-Host "`n✓ ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ SOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
