# Test Coverage Check Hook - Ensures API routes have corresponding tests
# Runs on PostToolUse after editing route files
# Warns (non-blocking) if test coverage gaps detected

$ErrorActionPreference = "Stop"

# Read hook input from stdin
$stdinContent = [Console]::In.ReadToEnd()

try {
    $hookData = $stdinContent | ConvertFrom-Json -ErrorAction Stop
} catch {
    # No valid JSON input - exit silently
    exit 0
}

if (-not $hookData) {
    # No valid JSON input - exit silently
    exit 0
}

# Only process file modification tools
$toolName = $hookData.tool.name
if ($toolName -notin @("create_file", "replace_string_in_file", "multi_replace_string_in_file")) {
    # Not a file edit - exit silently
    exit 0
}

# Extract file path(s) from tool parameters
$filePaths = @()
if ($toolName -eq "multi_replace_string_in_file") {
    $filePaths = $hookData.tool.parameters.replacements | ForEach-Object { $_.filePath }
} else {
    $filePaths = @($hookData.tool.parameters.filePath)
}

# Filter for API route files only (not spec files, not common.ts)
$routeFiles = $filePaths | Where-Object {
    $_ -match "[/\\]api[/\\]src[/\\]routes[/\\][^/\\]+\.ts$" -and
    $_ -notmatch "\.spec\.ts$" -and
    $_ -notmatch "[/\\]common\.ts$"
}

if ($routeFiles.Count -eq 0) {
    # No route files edited - exit silently
    exit 0
}

# Helper: Extract route handlers from a file
function Get-RouteHandlers {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @()
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $handlers = @()
    
    # Match: router.METHOD("path", async ...)
    # Captures method and path
    $pattern = 'router\.(get|post|put|delete|patch)\s*\(\s*[''"]([^''"]+)[''"]'
    $routeMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $routeMatches) {
        $method = $match.Groups[1].Value.ToUpper()
        $path = $match.Groups[2].Value
        $handlers += @{
            Method = $method
            Path = $path
        }
    }
    
    return $handlers
}

# Helper: Check if test exists for a route
function Test-RouteHasCoverage {
    param(
        [string]$SpecFilePath,
        [string]$ResourceName,
        [string]$Method,
        [string]$Path
    )
    
    if (-not (Test-Path $SpecFilePath)) {
        return $false
    }
    
    $specContent = Get-Content -Path $SpecFilePath -Raw
    
    # Look for describe block for this resource
    $describePattern = "describe\s*\(\s*[`"']$ResourceName[`"']"
    if ($specContent -notmatch $describePattern) {
        return $false
    }
    
    # Extract the describe block by finding matching braces
    $describeStart = $specContent.IndexOf($Matches[0])
    if ($describeStart -lt 0) {
        return $false
    }
    
    # Find the opening brace of the describe block
    $openBracePos = $specContent.IndexOf('{', $describeStart)
    if ($openBracePos -lt 0) {
        return $false
    }
    
    # Count braces to find the matching closing brace
    $braceCount = 1
    $pos = $openBracePos + 1
    $closeBracePos = -1
    
    while ($pos -lt $specContent.Length -and $braceCount -gt 0) {
        $char = $specContent[$pos]
        if ($char -eq '{') {
            $braceCount++
        } elseif ($char -eq '}') {
            $braceCount--
            if ($braceCount -eq 0) {
                $closeBracePos = $pos
                break
            }
        }
        $pos++
    }
    
    if ($closeBracePos -lt 0) {
        return $false
    }
    
    # Extract describe block content
    $describeBlock = $specContent.Substring($openBracePos + 1, $closeBracePos - $openBracePos - 1)
    
    # Check for test mentioning this method
    # Look for: it("can METHOD ...", or it("can GET/POST/PUT/DELETE ...",
    $testPattern = "it\s*\(\s*[`"'].*?\b$Method\b.*?[`"']"
    
    # Also check if the test calls a helper function that might match the path
    # Common patterns: createList, getList, updateList, deleteList, etc.
    $pathNormalized = $Path -replace ':', '' -replace '/', ''
    
    return ($describeBlock -match $testPattern) -or ($describeBlock -match [regex]::Escape($Path))
}

# Map route file names to describe block names in routes.spec.ts
$resourceMap = @{
    "lists.ts" = "Todo List Routes"
    "items.ts" = "Todo Item Routes"
}

# Analyze each edited route file
$warnings = @()
foreach ($routeFile in $routeFiles) {
    $fileName = Split-Path -Leaf $routeFile
    $resourceName = $resourceMap[$fileName]
    
    if (-not $resourceName) {
        # Unknown route file - skip
        continue
    }
    
    $handlers = Get-RouteHandlers -FilePath $routeFile
    if ($handlers.Count -eq 0) {
        continue
    }
    
    # Path to routes.spec.ts
    $routeDir = Split-Path -Parent $routeFile
    $specFile = Join-Path $routeDir "routes.spec.ts"
    
    # Check coverage for each handler
    $missingTests = @()
    foreach ($handler in $handlers) {
        $hasCoverage = Test-RouteHasCoverage -SpecFilePath $specFile -ResourceName $resourceName -Method $handler.Method -Path $handler.Path
        
        if (-not $hasCoverage) {
            $missingTests += "$($handler.Method) $($handler.Path)"
        }
    }
    
    if ($missingTests.Count -gt 0) {
        $relPath = $routeFile -replace '.*[/\\]src[/\\]', 'src/'
        $warnings += @{
            File = $relPath
            MissingTests = $missingTests
        }
    }
}

# Build system message if warnings found
if ($warnings.Count -gt 0) {
    $totalMissing = ($warnings | ForEach-Object { $_.MissingTests.Count } | Measure-Object -Sum).Sum
    
    $message = "⚠️  TEST COVERAGE GAP — $totalMissing route(s) without tests`r`n"
    $message += "These are warnings only. Changes have been saved.`r`n`r`n"
    
    foreach ($warning in $warnings) {
        $message += "📄 $($warning.File)`r`n"
        foreach ($missing in $warning.MissingTests) {
            $message += "  Missing test for: $missing`r`n"
        }
        $message += "`r`n"
    }
    
    $message += "💡 Would you like me to generate test skeletons for these routes?`r`n"
    $message += "   See: docs/testing-standards.md for test conventions"
    
    # Output hook result
    $result = @{
        hookSpecificOutput = @{
            hookEventName = "PostToolUse"
        }
        systemMessage = $message
    } | ConvertTo-Json -Depth 5 -Compress
    
    Write-Output $result
}

# Always exit 0 (non-blocking warning)
exit 0
