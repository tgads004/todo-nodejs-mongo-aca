# Debug script to understand why missing tests aren't detected

$ErrorActionPreference = "Stop"

$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"

# Create a temp test scenario
$tempDir = "$proj\src\test-temp-debug"
$tempRouteFile = "$tempDir\api\src\routes\lists.ts"
$tempSpecFile = "$tempDir\api\src\routes\routes.spec.ts"

# Create directories
New-Item -Path (Split-Path $tempRouteFile) -ItemType Directory -Force | Out-Null

# Route file with PATCH route
$routeContent = @'
import express from "express";
const router = express.Router();

router.get("/", async (req, res) => { res.json([]); });
router.post("/", async (req, res) => { res.status(201).json({}); });
router.patch("/:listId/archive", async (req, res) => { res.json({}); });

export default router;
'@

# Spec file without PATCH test
$specContent = @'
describe("Todo List Routes", () => {
    it("can GET an array of lists", async () => {
        // test GET
    });
    
    it("can POST (create) new list", async () => {
        // test POST
    });
});
'@

Set-Content -Path $tempRouteFile -Value $routeContent
Set-Content -Path $tempSpecFile -Value $specContent

Write-Host "Created temp files:" -ForegroundColor Cyan
Write-Host "  Route: $tempRouteFile"
Write-Host "  Spec:  $tempSpecFile"
Write-Host ""

# Test the Get-RouteHandlers function logic
Write-Host "Testing route handler extraction:" -ForegroundColor Yellow
$content = Get-Content -Path $tempRouteFile -Raw
$pattern = 'router\.(get|post|put|delete|patch)\s*\(\s*[''"]([^''"]+)[''"]'
$matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

Write-Host "Found $($matches.Count) routes:" -ForegroundColor Green
foreach ($match in $matches) {
    $method = $match.Groups[1].Value.ToUpper()
    $path = $match.Groups[2].Value
    Write-Host "  $method $path"
}
Write-Host ""

# Test the Test-RouteHasCoverage function logic
Write-Host "Testing coverage detection:" -ForegroundColor Yellow
$specContent = Get-Content -Path $tempSpecFile -Raw

$resourceName = "Todo List Routes"
$describePattern = "describe\s*\(\s*[`"']$resourceName[`"']"

Write-Host "Looking for describe block: $describePattern"
if ($specContent -match $describePattern) {
    Write-Host "  ✓ Found describe block" -ForegroundColor Green
    
    # Try to extract describe block
    $describeMatch = [regex]::Match($specContent, "$describePattern[\s\S]*?\{([\s\S]*?)\n\s*\}\s*\);", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($describeMatch.Success) {
        Write-Host "  ✓ Extracted describe block content" -ForegroundColor Green
        $describeBlock = $describeMatch.Groups[1].Value
        Write-Host "    Content length: $($describeBlock.Length) chars"
        
        # Check for each method
        foreach ($method in @("GET", "POST", "PATCH")) {
            $testPattern = "it\s*\(\s*[`"'].*?\b$method\b.*?[`"']"
            if ($describeBlock -match $testPattern) {
                Write-Host "  ✓ Found test for $method" -ForegroundColor Green
            } else {
                Write-Host "  ✗ Missing test for $method" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  ✗ Failed to extract describe block" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ Describe block not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press Enter to cleanup and exit..."
$null = Read-Host

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup complete"
