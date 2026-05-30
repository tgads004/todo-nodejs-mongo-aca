# Test JSON parsing of paths

$json = '{"tool":{"name":"test","parameters":{"filePath":"d:\\\\Projects\\\\Test\\\\file.ts"}}}'

Write-Host "JSON Input:" -ForegroundColor Cyan
Write-Host $json
Write-Host ""

$obj = $json | ConvertFrom-Json
$path = $obj.tool.parameters.filePath

Write-Host "Parsed Path:" -ForegroundColor Yellow
Write-Host $path
Write-Host ""

Write-Host "Path Length: $($path.Length)" -ForegroundColor Cyan
Write-Host "Expected Length (single backslashes): $('d:\Projects\Test\file.ts'.Length)"
Write-Host "Actual Length: $($path.Length)"
Write-Host ""

Write-Host "Character-by-character:" -ForegroundColor Yellow
for ($i = 0; $i -lt [Math]::Min(15, $path.Length); $i++) {
    $char = $path[$i]
    $charCode = [int]$char
    Write-Host "  [$i] = '$char' (code: $charCode)"
}
