#!/usr/bin/env pwsh
# Standards enforcement hook
# Warns about project-specific patterns that lint cannot catch.
# PostToolUse — runs after file edits, non-blocking (always exits 0).
#
# Checks:
#   1. API routes:         Request<> generics on async handlers
#   2. API routes:         try/catch required in async handlers
#   3. React components:   FC<Props> type annotation on exported components
#   4. React components:   No raw HTML elements (use Fluent UI)
#   5. All TypeScript:     No 'any' outside catch blocks
#   6. Test files:         afterAll cleanup when beforeAll creates data
#
# Per-file opt-out:  add  // standards-check: disable  anywhere in the file.

param()

# ─── Read hook input from stdin ───────────────────────────────────────────────
# Use $input automatic variable for proper PowerShell pipeline support
$stdinLines   = @($input)
if ($stdinLines.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PostToolUse"}}'
    exit 0
}
$stdinContent = $stdinLines -join "`n"
$hookData     = $stdinContent | ConvertFrom-Json -ErrorAction SilentlyContinue

# ─── Extract edited file paths from supported edit tools ─────────────────────
$toolName    = $hookData.tool.name
$editedFiles = @()

switch ($toolName) {
    "replace_string_in_file" {
        if ($hookData.tool.parameters.filePath) {
            $editedFiles += $hookData.tool.parameters.filePath
        }
    }
    "multi_replace_string_in_file" {
        foreach ($r in $hookData.tool.parameters.replacements) {
            if ($r.filePath) { $editedFiles += $r.filePath }
        }
    }
    "create_file" {
        if ($hookData.tool.parameters.filePath) {
            $editedFiles += $hookData.tool.parameters.filePath
        }
    }
    default {
        # Not a file-edit operation — nothing to check
        Write-Output '{"hookSpecificOutput":{"hookEventName":"PostToolUse"}}'
        exit 0
    }
}

# Filter: TypeScript source files only (exclude node_modules, dist, build)
$tsFiles = $editedFiles | Where-Object {
    $_ -match "[/\\]src[/\\].*\.tsx?$"    -and
    $_ -notmatch "node_modules"            -and
    $_ -notmatch "[/\\](dist|build)[/\\]"
} | Select-Object -Unique

if ($tsFiles.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PostToolUse"}}'
    exit 0
}

# ─── Helper: resolve character index → 1-based line number ───────────────────
function Get-LineNumber {
    param([string]$content, [int]$charIndex)
    return ($content.Substring(0, $charIndex) -split "`n").Count
}

# ─── Helper: extract handler body starting from a character position ──────────
# Scans forward for the first '{' then tracks depth until it closes.
# Returns the body text (including the outer braces), or "" if not found.
function Get-HandlerBody {
    param([string]$content, [int]$startIndex)
    $depth   = 0
    $entered = $false
    for ($i = $startIndex; $i -lt $content.Length; $i++) {
        $ch = $content[$i]
        if ($ch -eq '{') {
            $depth++
            $entered = $true
        } elseif ($ch -eq '}') {
            $depth--
            if ($entered -and $depth -eq 0) {
                return $content.Substring($startIndex, $i - $startIndex + 1)
            }
        }
    }
    return ""
}

# ─── Collect warnings across all edited files ─────────────────────────────────
$allWarnings = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($file in $tsFiles) {
    if (-not (Test-Path $file)) { continue }

    $raw = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { continue }

    # Per-file opt-out
    if ($raw -match "//\s*standards-check:\s*disable") { continue }

    $lines = $raw -split "`n"

    # Relative path for readable output
    $projectRoot  = (Get-Location).Path
    $relativePath = $file.Replace("$projectRoot\", "").Replace("$projectRoot/", "").Replace("\", "/")

    # ── File type classification ───────────────────────────────────────────────
    $isApiRoute = $file -match "[/\\]api[/\\]src[/\\]routes[/\\][^/\\]+\.ts$" `
                  -and $file -notmatch "\.spec\.ts$"
    $isReactTsx = $file -match "\.tsx$"
    $isTest     = $file -match "\.spec\.ts$"

    $fileWarnings = [System.Collections.Generic.List[PSCustomObject]]::new()

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 1 — API Routes: Request<> generics on async handlers
    # ────────────────────────────────────────────────────────────────────────────
    if ($isApiRoute) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # Async route handler where req has no type annotation at all
            if ($line -match "router\.(get|post|put|patch|delete|all)\(" -and
                $line -match "async\s*\(\s*req\s*[,)]") {
                $fileWarnings.Add([PSCustomObject]@{
                    line    = $i + 1
                    code    = $line.Trim()
                    message = "Route handler 'req' is untyped — add Request<> generics"
                    fix     = "async (req: Request<PathParams, ResBody, ReqBody, QueryParams>, res): Promise<void> =>"
                    docs    = "docs/api-standards.md — Request Typing"
                })
            }
        }
    }

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 2 — API Routes: try/catch required in async handlers
    # ────────────────────────────────────────────────────────────────────────────
    if ($isApiRoute) {
        $routeRx = [regex]::new(
            'router\.(get|post|put|patch|delete|all)\s*\([^,)]+,\s*async',
            [System.Text.RegularExpressions.RegexOptions]::None
        )
        foreach ($match in $routeRx.Matches($raw)) {
            $body = Get-HandlerBody -content $raw -startIndex $match.Index
            if ($body -and $body -notmatch '\btry\s*\{') {
                $lineNum  = Get-LineNumber -content $raw -charIndex $match.Index
                $codeLine = $lines[$lineNum - 1].Trim()
                $fileWarnings.Add([PSCustomObject]@{
                    line    = $lineNum
                    code    = $codeLine
                    message = "Async route handler is missing a try/catch block"
                    fix     = "try { /* handler */ } catch (err: any) { res.status(500).json({ error: 'Internal server error' }) }"
                    docs    = "docs/api-standards.md — Route Handler Pattern"
                })
            }
        }
    }

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 3 — React: FC<Props> type annotation on exported components
    # ────────────────────────────────────────────────────────────────────────────
    if ($isReactTsx) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # Exported arrow function starting with uppercase (likely a component)
            # that does NOT already have : FC< on the same line or next 2 lines
            if ($line -match "^export\s+const\s+[A-Z]\w+\s*=\s*[({]" -and
                $line -notmatch ":\s*(React\.)?FC\s*<") {
                $peek = ($lines[$i..([Math]::Min($i + 2, $lines.Count - 1))] -join " ")
                if ($peek -notmatch ":\s*(React\.)?FC\s*<") {
                    $fileWarnings.Add([PSCustomObject]@{
                        line    = $i + 1
                        code    = $line.Trim()
                        message = "Exported component missing FC<Props> type annotation"
                        fix     = "const MyComponent: FC<MyComponentProps> = ({ prop }) => { ... }"
                        docs    = "docs/web-standards.md — Component Pattern"
                    })
                }
            }
        }
    }

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 4 — React: No raw HTML elements (use Fluent UI)
    # ────────────────────────────────────────────────────────────────────────────
    if ($isReactTsx) {
        $rawTags = "div|button|input|span|form|p|h[1-6]|ul|ol|li|select|textarea|img|table"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $trimmed = $lines[$i].TrimStart()
            # Skip comment and JSDoc lines
            if ($trimmed -match "^(//|\*|/\*)") { continue }
            # Only fire when tag is at start of trimmed line (JSX return indentation pattern)
            if ($trimmed -match "^<($rawTags)[\s>/]") {
                $tag = [regex]::Match($trimmed, "^<($rawTags)[\s>/]").Groups[1].Value
                $fileWarnings.Add([PSCustomObject]@{
                    line    = $i + 1
                    code    = $trimmed.Substring(0, [Math]::Min(80, $trimmed.Length))
                    message = "Raw HTML <$tag> — replace with a Fluent UI component"
                    fix     = "Use: <Stack> <DefaultButton> <PrimaryButton> <TextField> <Text> <Checkbox> <Image> <List>"
                    docs    = "docs/ui-components.md"
                })
            }
        }
    }

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 5 — All TypeScript: No 'any' outside catch blocks
    # ────────────────────────────────────────────────────────────────────────────
    $inCatch     = $false
    $catchDepth  = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line    = $lines[$i]
        $trimmed = $line.TrimStart()

        # Skip comment and JSDoc lines
        if ($trimmed -match "^(//|\*|/\*)") { continue }

        # Track catch block enter / exit with brace depth
        if ($line -match "\bcatch\s*\(") {
            $inCatch    = $true
            $catchDepth = 0
        }
        if ($inCatch) {
            $catchDepth += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
            $catchDepth -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            if ($catchDepth -le 0 -and $i -gt 0) { $inCatch = $false }
        }

        if (-not $inCatch) {
            $hasAnyType  = $line -match ":\s*any\b"
            $hasAnyCast  = $line -match "\bas\s+any\b"
            $isCatchDecl = $line -match "\bcatch\s*\(\s*\w+\s*:\s*any\s*\)"

            if (($hasAnyType -or $hasAnyCast) -and -not $isCatchDecl) {
                $fileWarnings.Add([PSCustomObject]@{
                    line    = $i + 1
                    code    = $line.Trim()
                    message = "'any' used outside a catch block"
                    fix     = "Use a specific type or 'unknown' with a type guard. Only catch (err: any) is permitted."
                    docs    = "docs/api-standards.md — TypeScript Conventions"
                })
            }
        }
    }

    # ────────────────────────────────────────────────────────────────────────────
    # CHECK 6 — Tests: afterAll cleanup when beforeAll creates data
    # ────────────────────────────────────────────────────────────────────────────
    if ($isTest) {
        $hasBeforeAll = $raw -match "\bbeforeAll\s*\("
        $createsData  = $raw -match "\.(post|put|patch)\s*\(" -or
                        $raw -match "\.(insert|create|seed|upsert)" -or
                        $raw -match "\b(insert|create|seed|upsert)\s*\("
        $hasAfterAll  = $raw -match "\bafterAll\s*\("

        if ($hasBeforeAll -and $createsData -and -not $hasAfterAll) {
            $fileWarnings.Add([PSCustomObject]@{
                line    = 1
                code    = "(file-level)"
                message = "Test creates data in beforeAll but has no afterAll cleanup"
                fix     = "afterAll(async () => { /* delete test data created in beforeAll */ })"
                docs    = "docs/testing-standards.md"
            })
        }
    }

    # Accumulate with file path
    foreach ($w in $fileWarnings) {
        $allWarnings.Add([PSCustomObject]@{
            file    = $relativePath
            line    = $w.line
            code    = $w.code
            message = $w.message
            fix     = $w.fix
            docs    = $w.docs
        })
    }
}

# ─── Build output ─────────────────────────────────────────────────────────────
if ($allWarnings.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PostToolUse"}}'
    exit 0
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("⚠️  STANDARDS CHECK — $($allWarnings.Count) violation(s) found")
[void]$sb.AppendLine("These are warnings only. Changes have been saved.")
[void]$sb.AppendLine("")

$currentFile = $null
foreach ($w in $allWarnings) {
    if ($w.file -ne $currentFile) {
        if ($currentFile -ne $null) { [void]$sb.AppendLine("") }
        $currentFile = $w.file
        [void]$sb.AppendLine("📄 $($w.file)")
    }
    [void]$sb.AppendLine("  Line $($w.line): $($w.message)")
    [void]$sb.AppendLine("  Code: $($w.code)")
    [void]$sb.AppendLine("  Fix:  $($w.fix)")
    [void]$sb.AppendLine("  Ref:  $($w.docs)")
    [void]$sb.AppendLine("")
}

[void]$sb.Append("To disable per file add:  // standards-check: disable")

$result = @{
    hookSpecificOutput = @{ hookEventName = "PostToolUse" }
    systemMessage      = $sb.ToString()
} | ConvertTo-Json -Depth 5

Write-Output $result
exit 0
