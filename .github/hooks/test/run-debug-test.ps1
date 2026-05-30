# Test with debug hook

$proj = "d:\Projects\Test Automation\Playwright\agentic architecture\todo-nodejs-mongo-aca"

# Create temp scenario
$tempDir = "$proj\src\test-temp-debug2"
$routeFile = "$tempDir\api\src\routes\lists.ts"
New-Item -Path (Split-Path $routeFile) -ItemType Directory -Force | Out-Null

@'
import express from "express";
const router = express.Router();
router.patch("/:id", async (req, res) => { res.json({}); });
export default router;
'@ | Set-Content -Path $routeFile

# Clean log
Remove-Item "c:\temp\hook-debug.log" -ErrorAction SilentlyContinue

# Run debug hook
$filePathEscaped = $routeFile -replace '\\', '\\\\'
$json = "{`"tool`":{`"name`":`"replace_string_in_file`",`"parameters`":{`"filePath`":`"$filePathEscaped`"}}}"
$json | pwsh -NoProfile -File "$proj\.github\hooks\test\test-coverage-check-debug.ps1"

Write-Host "`nDebug Log:" -ForegroundColor Cyan
Get-Content "c:\temp\hook-debug.log"

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
