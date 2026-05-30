# Simple test to verify hook detects missing coverage

$ErrorActionPreference = "Stop"

$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"

# Create temp scenario  
$tempDir = "$proj\src\test-temp-simple"
$routeFile = "$tempDir\api\src\routes\lists.ts"
$specFile = "$tempDir\api\src\routes\routes.spec.ts"

New-Item -Path (Split-Path $routeFile) -ItemType Directory -Force | Out-Null

# Route with PATCH (uncovered)
@'
import express from "express";
const router = express.Router();
router.get("/", async (req, res) => { res.json([]); });
router.patch("/:listId", async (req, res) => { res.json({}); });
export default router;
'@ | Set-Content -Path $routeFile

# Spec with only GET test
@'
describe("Todo List Routes", () => {
    it("can GET an array of lists", async () => {});
});
'@ | Set-Content -Path $specFile

Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  $routeFile"
Write-Host "  $specFile"
Write-Host ""

# Build JSON input
$filePathEscaped = $routeFile -replace '\\', '\\\\'
$json = "{`"tool`":{`"name`":`"replace_string_in_file`",`"parameters`":{`"filePath`":`"$filePathEscaped`"}}}"

Write-Host "JSON Input:" -ForegroundColor Yellow
Write-Host $json
Write-Host ""

Write-Host "Hook Output:" -ForegroundColor Yellow
$output = $json | pwsh -NoProfile -File "$proj\.github\hooks\scripts\test-coverage-check.ps1" 2>&1 | Out-String

if ($output.Trim() -eq "") {
    Write-Host "(empty)" -ForegroundColor Red
} else {
    Write-Host $output -ForegroundColor Green
}

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`nCleanup complete"
