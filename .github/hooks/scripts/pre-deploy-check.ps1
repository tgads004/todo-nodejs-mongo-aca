#!/usr/bin/env pwsh
# Pre-deploy validation hook
# Validates infrastructure and configuration before Azure deployments

param()

# Read the hook input from stdin
$hookInput = [Console]::In.ReadToEnd()
$hookData = $hookInput | ConvertFrom-Json -ErrorAction SilentlyContinue

# Check if this is a deployment operation
$toolName = $hookData.tool.name
$command = $hookData.tool.parameters.command

$isDeployment = $false
$deploymentType = ""

if ($toolName -eq "run_in_terminal" -and $command) {
    # Check for Azure deployment commands
    if ($command -match "azd\s+up") {
        $isDeployment = $true
        $deploymentType = "azd up (provision + deploy)"
    } elseif ($command -match "azd\s+provision") {
        $isDeployment = $true
        $deploymentType = "azd provision (infrastructure only)"
    } elseif ($command -match "azd\s+deploy") {
        $isDeployment = $true
        $deploymentType = "azd deploy (code only)"
    } elseif ($command -match "az\s+deployment") {
        $isDeployment = $true
        $deploymentType = "az deployment (Bicep/ARM)"
    }
    
    # Allow preview/dry-run commands without validation
    if ($command -match "--preview|--what-if|--dry-run") {
        $isDeployment = $false
    }
}

# If not a deployment, allow it
if (-not $isDeployment) {
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "allow"
        }
    } | ConvertTo-Json -Depth 10
    Write-Output $output
    exit 0
}

# Run pre-deployment validation
Write-Host "🔍 Running pre-deployment validation for: $deploymentType" -ForegroundColor Cyan
Write-Host ""

$failures = @()
$warnings = @()

# Check 1: Azure CLI installed and logged in
Write-Host "  Checking Azure CLI authentication..." -ForegroundColor Gray
$azInstalled = Get-Command az -ErrorAction SilentlyContinue
if (-not $azInstalled) {
    $failures += @{
        check = "Azure CLI"
        message = "Azure CLI (az) not found in PATH"
        fix = "Install Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli"
    }
} else {
    $azAccount = az account show 2>&1
    $azExitCode = $LASTEXITCODE
    if ($azExitCode -ne 0) {
        $failures += @{
            check = "Azure CLI Authentication"
            message = "Not logged in to Azure CLI"
            fix = "az login"
        }
    } else {
        $accountInfo = $azAccount | ConvertFrom-Json
        Write-Host "    ✅ Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
    }
}

# Check 2: Bicep validation
Write-Host "  Validating Bicep files..." -ForegroundColor Gray
$bicepFiles = Get-ChildItem -Path "infra" -Filter "*.bicep" -Recurse -ErrorAction SilentlyContinue

if ($bicepFiles.Count -eq 0) {
    $warnings += @{
        check = "Bicep Files"
        message = "No Bicep files found in infra/ directory"
    }
} else {
    $bicepErrors = @()
    foreach ($bicepFile in $bicepFiles) {
        $buildResult = az bicep build --file $bicepFile.FullName 2>&1
        $buildExitCode = $LASTEXITCODE
        if ($buildExitCode -ne 0) {
            $bicepErrors += "  $($bicepFile.Name): $buildResult"
        }
    }
    
    if ($bicepErrors.Count -gt 0) {
        $failures += @{
            check = "Bicep Validation"
            message = "Bicep compilation failed"
            output = ($bicepErrors | Select-Object -First 5) -join "`n"
            fix = "Fix Bicep syntax errors. Run: az bicep build --file infra/main.bicep"
        }
    } else {
        Write-Host "    ✅ All Bicep files valid ($($bicepFiles.Count) files)" -ForegroundColor Green
    }
}

# Check 3: Environment variables (azd env)
Write-Host "  Checking azd environment..." -ForegroundColor Gray
$azdEnvList = azd env list 2>&1
if ($LASTEXITCODE -eq 0 -and $azdEnvList -match "\(Current\)") {
    Write-Host "    ✅ azd environment configured" -ForegroundColor Green
} else {
    $failures += @{
        check = "azd Environment"
        message = "No active azd environment found"
        fix = "azd env new <environment-name> OR azd env select <environment-name>"
    }
}

# Check 4: Required environment variables for app
Write-Host "  Checking required environment variables..." -ForegroundColor Gray
$requiredEnvVars = @()

# Check if variables are set in azd env
$envVars = azd env get-values 2>&1
if ($LASTEXITCODE -eq 0) {
    # Parse environment variables
    $envHash = @{}
    $envVars | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $envHash[$matches[1]] = $matches[2]
        }
    }
    
    # These are typically needed but might not exist yet on first deployment
    $recommendedVars = @("AZURE_LOCATION", "AZURE_SUBSCRIPTION_ID")
    foreach ($varName in $recommendedVars) {
        if (-not $envHash.ContainsKey($varName) -or [string]::IsNullOrWhiteSpace($envHash[$varName])) {
            $warnings += @{
                check = "Environment Variables"
                message = "Recommended variable not set: $varName"
                fix = "azd env set $varName <value>"
            }
        }
    }
}

# Check 5: Secrets scan in infrastructure files
Write-Host "  Scanning for hardcoded secrets in infrastructure..." -ForegroundColor Gray
$infraFiles = Get-ChildItem -Path "infra" -Include "*.bicep", "*.json" -Recurse -ErrorAction SilentlyContinue

$secretPatterns = @(
    "password\s*[:=]\s*['\`"][^'\`"]{8,}['\`"]",
    "key\s*[:=]\s*['\`"][^'\`"]{20,}['\`"]",
    "connectionString\s*[:=]\s*['\`"][^'\`"]{20,}['\`"]",
    "secret\s*[:=]\s*['\`"][^'\`"]{8,}['\`"]"
)

foreach ($file in $infraFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                # Exclude common parameter declarations and secure strings
                if ($content -notmatch "@secure|securestring|keyVault|secretUri|reference\(") {
                    $failures += @{
                        check = "Infrastructure Secrets Scan"
                        message = "Potential hardcoded secret in $($file.Name)"
                        fix = "Use Key Vault references or @secure parameters in Bicep"
                        doc = "docs/infrastructure.md"
                    }
                    break
                }
            }
        }
    }
}

# Check 6: Required tags in Bicep resources (if main.bicep exists)
Write-Host "  Checking required tags in Bicep resources..." -ForegroundColor Gray
$mainBicep = Get-Item "infra/main.bicep" -ErrorAction SilentlyContinue
if ($mainBicep) {
    $bicepContent = Get-Content $mainBicep.FullName -Raw
    
    # Look for resource declarations
    $resourceMatches = [regex]::Matches($bicepContent, "resource\s+\w+\s+'[^']+@[^']+'\s*=\s*{")
    
    if ($resourceMatches.Count -gt 0) {
        # Check if tags are generally used
        if ($bicepContent -notmatch "tags\s*:") {
            $warnings += @{
                check = "Bicep Resource Tags"
                message = "No tags found in main.bicep - consider adding tags for cost tracking"
                fix = "Add tags object to resources, including 'azd-env-name' and 'Owner'"
                doc = "docs/infrastructure.md"
            }
        }
    }
}

# Check 7: Azure subscription has required resource providers
Write-Host "  Checking Azure resource providers..." -ForegroundColor Gray
if ($azInstalled) {
    az account show 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $requiredProviders = @(
            "Microsoft.App",           # Container Apps
            "Microsoft.DocumentDB",    # Cosmos DB
            "Microsoft.ContainerRegistry", # ACR
            "Microsoft.KeyVault"       # Key Vault
        )
        
        $unregisteredProviders = @()
        foreach ($provider in $requiredProviders) {
            $providerState = az provider show --namespace $provider --query "registrationState" -o tsv 2>&1
            if ($LASTEXITCODE -eq 0 -and $providerState -ne "Registered") {
                $unregisteredProviders += $provider
            }
        }
        
        if ($unregisteredProviders.Count -gt 0) {
            $warnings += @{
                check = "Azure Resource Providers"
                message = "Some required providers not registered: $($unregisteredProviders -join ', ')"
                fix = "az provider register --namespace <provider-name> (may take 5-10 minutes)"
            }
        } else {
            Write-Host "    ✅ All required resource providers registered" -ForegroundColor Green
        }
    }
}

Write-Host ""

# Determine outcome
if ($failures.Count -gt 0) {
    Write-Host "❌ Pre-deployment validation FAILED!" -ForegroundColor Red
    Write-Host ""
    
    foreach ($failure in $failures) {
        Write-Host "  ❌ $($failure.check)" -ForegroundColor Red
        Write-Host "     $($failure.message)" -ForegroundColor Yellow
        if ($failure.output) {
            Write-Host "     $($failure.output)" -ForegroundColor Gray
        }
        Write-Host "     Fix: $($failure.fix)" -ForegroundColor Cyan
        if ($failure.doc) {
            Write-Host "     See: $($failure.doc)" -ForegroundColor Blue
        }
        Write-Host ""
    }
    
    Write-Host "To preview changes without validation:" -ForegroundColor Gray
    Write-Host "  azd provision --preview" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To bypass validation (not recommended):" -ForegroundColor Gray
    Write-Host "  Run the command directly in terminal (not through Copilot)" -ForegroundColor Gray
    Write-Host ""
    
    # Block the deployment
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = "$($failures.Count) pre-deployment check(s) failed. Fix issues before deploying."
        }
        systemMessage = "❌ Pre-deployment validation failed. See output above for details."
    } | ConvertTo-Json -Depth 10
    
    Write-Output $output
    exit 2
}

# Show warnings but allow deployment
if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Pre-deployment warnings (non-blocking):" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($warning in $warnings) {
        Write-Host "  ⚠️  $($warning.check)" -ForegroundColor Yellow
        Write-Host "     $($warning.message)" -ForegroundColor Gray
        if ($warning.fix) {
            Write-Host "     Fix: $($warning.fix)" -ForegroundColor Cyan
        }
        if ($warning.doc) {
            Write-Host "     See: $($warning.doc)" -ForegroundColor Blue
        }
        Write-Host ""
    }
}

# All checks passed
Write-Host "✅ Pre-deployment validation passed!" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment type: $deploymentType" -ForegroundColor Cyan
Write-Host "Ready to deploy to Azure." -ForegroundColor Green
Write-Host ""

$output = @{
    hookSpecificOutput = @{
        hookEventName = "PreToolUse"
        permissionDecision = "allow"
    }
} | ConvertTo-Json -Depth 10

Write-Output $output
exit 0
