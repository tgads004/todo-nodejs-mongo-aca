#!/usr/bin/env pwsh
# Test script for standards-check.ps1 hook
# Creates temporary test files with various violations, runs the hook, and validates output

$ErrorActionPreference = "Stop"

# ─── Setup ───────────────────────────────────────────────────────────────────
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$hookScript  = Join-Path $projectRoot ".github\hooks\scripts\standards-check.ps1"
$tempDir     = Join-Path $projectRoot "src\test-temp-$(Get-Random)"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Testing standards-check.ps1 hook" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $hookScript)) {
    Write-Error "Hook script not found at: $hookScript"
    exit 1
}

# Create temp directory structure
New-Item -ItemType Directory -Path "$tempDir\api\src\routes" -Force | Out-Null
New-Item -ItemType Directory -Path "$tempDir\web\src\components" -Force | Out-Null

# ─── Helper: Run hook with simulated input ───────────────────────────────────
function Invoke-Hook {
    param(
        [string]$ToolName,
        [hashtable]$Parameters
    )

    $hookInput = @{
        tool = @{
            name       = $ToolName
            parameters = $Parameters
        }
    } | ConvertTo-Json -Depth 5

    # Write input to temp file and redirect as stdin
    $tempInput = [System.IO.Path]::GetTempFileName()
    $hookInput | Set-Content $tempInput -NoNewline
    
    try {
        $result = Get-Content $tempInput | & $hookScript 2>&1
        $output = $result -join "`n"
        return ($output | ConvertFrom-Json -ErrorAction SilentlyContinue)
    } finally {
        Remove-Item $tempInput -Force -ErrorAction SilentlyContinue
    }
}

# ─── Test counters ────────────────────────────────────────────────────────────
$testsPassed = 0
$testsFailed = 0

# ─── Test helper ──────────────────────────────────────────────────────────────
function Test-Scenario {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "🧪 $Name" -ForegroundColor Yellow
    try {
        & $Test
        Write-Host "   ✓ PASS" -ForegroundColor Green
        $script:testsPassed++
    } catch {
        Write-Host "   ✗ FAIL: $_" -ForegroundColor Red
        $script:testsFailed++
    }
    Write-Host ""
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1: API Route with untyped req parameter
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "API Route - Untyped req parameter" {
    $file = "$tempDir\api\src\routes\test1.ts"
    @"
import { Router } from 'express';
const router = Router();

router.get('/items', async (req, res) => {
    const items = await db.collection('items').find().toArray();
    res.json(items);
});

export default router;
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "replace_string_in_file" -Parameters @{
        filePath  = $file
        oldString = "dummy"
        newString = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for untyped req parameter"
    }
    if ($result.systemMessage -notmatch "Request<> generics") {
        throw "Expected 'Request<> generics' message"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2: API Route missing try/catch
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "API Route - Missing try/catch" {
    $file = "$tempDir\api\src\routes\test2.ts"
    @"
import { Router, Request, Response } from 'express';
const router = Router();

router.post('/items', async (req: Request, res: Response) => {
    const result = await db.collection('items').insertOne(req.body);
    res.status(201).json(result);
});

export default router;
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "create_file" -Parameters @{
        filePath = $file
        content  = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for missing try/catch"
    }
    if ($result.systemMessage -notmatch "try/catch") {
        throw "Expected 'try/catch' message"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3: React component without FC<Props> type
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "React - Missing FC type annotation" {
    $file = "$tempDir\web\src\components\TestComponent.tsx"
    @"
import React from 'react';

interface TestProps {
    title: string;
}

export const TestComponent = ({ title }: TestProps) => {
    return <div>{title}</div>;
};
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "replace_string_in_file" -Parameters @{
        filePath  = $file
        oldString = "dummy"
        newString = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for missing FC type"
    }
    if ($result.systemMessage -notmatch "FC<Props>") {
        throw "Expected 'FC<Props>' message"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4: React component with raw HTML elements
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "React - Raw HTML elements" {
    $file = "$tempDir\web\src\components\TestComponent2.tsx"
    @"
import React, { FC } from 'react';

interface Props {
    message: string;
}

export const TestComponent: FC<Props> = ({ message }) => {
    return (
        <div>
            <h1>Title</h1>
            <button onClick={() => alert('clicked')}>Click me</button>
            <p>{message}</p>
        </div>
    );
};
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "create_file" -Parameters @{
        filePath = $file
        content  = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for raw HTML"
    }
    if ($result.systemMessage -notmatch "Raw HTML") {
        throw "Expected 'Raw HTML' message"
    }
    # Should detect div, h1, button, p
    $violations = ([regex]::Matches($result.systemMessage, "Raw HTML")).Count
    if ($violations -lt 3) {
        throw "Expected at least 3 raw HTML violations, found $violations"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 5: TypeScript with 'any' outside catch block
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "TypeScript - 'any' outside catch block" {
    $file = "$tempDir\api\src\routes\test3.ts"
    @"
import { Router, Request, Response } from 'express';

const router = Router();

function processData(data: any) {
    return data.map((item: any) => item.value);
}

router.get('/data', async (req: Request, res: Response): Promise<void> => {
    try {
        const result = processData([]);
        res.json(result);
    } catch (err: any) {
        res.status(500).json({ error: 'Failed' });
    }
});

export default router;
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "replace_string_in_file" -Parameters @{
        filePath  = $file
        oldString = "dummy"
        newString = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for 'any' usage"
    }
    if ($result.systemMessage -notmatch "'any' used outside") {
        throw "Expected 'any' usage message"
    }
    # Should catch the two 'any' in processData but NOT the catch (err: any)
    $violations = ([regex]::Matches($result.systemMessage, "'any' used outside")).Count
    if ($violations -lt 2) {
        throw "Expected at least 2 'any' violations, found $violations"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 6: Test file with beforeAll but no afterAll
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "Test - beforeAll without afterAll cleanup" {
    $file = "$tempDir\api\src\routes\test.spec.ts"
    @"
import request from 'supertest';
import app from '../app';

describe('Items API', () => {
    beforeAll(async () => {
        await db.collection('items').insertMany([
            { name: 'Test 1' },
            { name: 'Test 2' }
        ]);
    });

    it('should get items', async () => {
        const response = await request(app).get('/items');
        expect(response.status).toBe(200);
    });
});
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "create_file" -Parameters @{
        filePath = $file
        content  = "dummy"
    }

    if (-not $result.systemMessage) {
        throw "Expected warning for missing afterAll"
    }
    if ($result.systemMessage -notmatch "afterAll") {
        throw "Expected 'afterAll' message"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 7: Compliant API route (should pass without warnings)
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "API Route - Compliant code (no warnings)" {
    $file = "$tempDir\api\src\routes\compliant.ts"
    @"
import { Router, Request, Response } from 'express';

const router = Router();

router.get('/items', async (req: Request, res: Response): Promise<void> => {
    try {
        const items = await db.collection('items').find().toArray();
        res.json(items);
    } catch (err: any) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "replace_string_in_file" -Parameters @{
        filePath  = $file
        oldString = "dummy"
        newString = "dummy"
    }

    if ($result.systemMessage) {
        throw "Expected no warnings for compliant code, got: $($result.systemMessage)"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 8: File with standards-check: disable comment
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "File opt-out - standards-check: disable" {
    $file = "$tempDir\api\src\routes\disabled.ts"
    @"
// standards-check: disable
import { Router } from 'express';
const router = Router();

router.get('/items', async (req, res) => {
    // This has violations but should be ignored
    const items: any = await db.collection('items').find().toArray();
    res.json(items);
});

export default router;
"@ | Set-Content $file

    $result = Invoke-Hook -ToolName "create_file" -Parameters @{
        filePath = $file
        content  = "dummy"
    }

    if ($result.systemMessage) {
        throw "Expected no warnings when standards-check is disabled, got: $($result.systemMessage)"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 9: Multi-file edit (multi_replace_string_in_file)
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "Multi-file edit - Multiple violations across files" {
    $file1 = "$tempDir\api\src\routes\multi1.ts"
    $file2 = "$tempDir\api\src\routes\multi2.ts"

    @"
import { Router } from 'express';
const router = Router();
router.get('/test', async (req, res) => {
    res.json({ ok: true });
});
export default router;
"@ | Set-Content $file1

    @"
import { Router } from 'express';
const router = Router();
router.post('/test', async (req, res) => {
    res.json({ ok: true });
});
export default router;
"@ | Set-Content $file2

    $result = Invoke-Hook -ToolName "multi_replace_string_in_file" -Parameters @{
        replacements = @(
            @{ filePath = $file1; oldString = "dummy"; newString = "dummy" }
            @{ filePath = $file2; oldString = "dummy"; newString = "dummy" }
        )
    }

    if (-not $result.systemMessage) {
        throw "Expected warnings for multi-file violations"
    }
    if ($result.systemMessage -notmatch "multi1\.ts") {
        throw "Expected warning for multi1.ts"
    }
    if ($result.systemMessage -notmatch "multi2\.ts") {
        throw "Expected warning for multi2.ts"
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 10: Non-file-edit tool (should exit cleanly)
# ══════════════════════════════════════════════════════════════════════════════
Test-Scenario "Non-file-edit tool - Should exit cleanly" {
    $result = Invoke-Hook -ToolName "semantic_search" -Parameters @{
        query = "test"
    }

    if ($result.systemMessage) {
        throw "Expected no output for non-file-edit tool"
    }
    if ($result.hookSpecificOutput.hookEventName -ne "PostToolUse") {
        throw "Expected PostToolUse event"
    }
}

# ─── Cleanup ──────────────────────────────────────────────────────────────────
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Cleaning up..." -ForegroundColor Yellow
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}

# ─── Results ──────────────────────────────────────────────────────────────────
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some tests failed" -ForegroundColor Red
    exit 1
}
