#!/usr/bin/env pwsh
# check-links.ps1
# A script to check markdown links in wiki files using lychee

# Parse command line arguments
param (
    [Parameter(Position = 0)]
    [string]$Target = "all",
    
    [Parameter()]
    [switch]$JsonOutput,
    
    [Parameter()]
    [string]$OutputFile,
    
    [Parameter()]
    [switch]$SkipLocalFiles,
    
    [Parameter()]
    [string[]]$ExcludePatterns = @()
)

# Check if lychee is installed
function Test-Command {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    
    try {
        if (Get-Command $Command) {
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Install lychee if not already installed
$lycheeInstalled = Test-Command -Command "lychee"
if (-not $lycheeInstalled) {
    Write-Host "lychee is not installed. Installing with Cargo..." -ForegroundColor Yellow
    
    # Check if Cargo is installed
    if (-not (Test-Command -Command "cargo")) {
        Write-Host "Cargo is not installed. Please install Rust and Cargo first:" -ForegroundColor Red
        Write-Host "Visit https://www.rust-lang.org/tools/install for installation instructions." -ForegroundColor Red
        exit 1
    }
    
    # Install lychee using Cargo
    cargo install lychee
    
    if (-not $?) {
        Write-Host "Failed to install lychee. Please check your Rust/Cargo installation." -ForegroundColor Red
        exit 1
    }
    
    # Attempt to add cargo bin to path for this session
    if ($IsWindows) {
        $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
    } else {
        $env:PATH = "$env:HOME/.cargo/bin:$env:PATH"
    }
    
    # Verify lychee is now available
    $lycheeInstalled = Test-Command -Command "lychee"
    if (-not $lycheeInstalled) {
        Write-Host "Lychee was installed but still cannot be found in PATH." -ForegroundColor Yellow
        Write-Host "Will attempt to use full path to lychee executable." -ForegroundColor Yellow
    }
}

# Set up base paths
$docsPath = "$PSScriptRoot/.."
$wikiPath = "$PSScriptRoot/../docs.wiki"

# Define path to lychee executable
$lycheePath = "lychee"

# Check standard cargo bin path on MacOS/Linux
$cargoBinPath = "$env:HOME/.cargo/bin/lychee"
if ($IsWindows) {
    $cargoBinPath = "$env:USERPROFILE\.cargo\bin\lychee.exe"
}

# If Cargo bin path exists, use it directly
if (Test-Path $cargoBinPath) {
    $lycheePath = $cargoBinPath
    Write-Host "Using lychee at Cargo path: $lycheePath" -ForegroundColor Yellow
}

# Configure lychee command base
$lycheeArgs = @("--no-progress")

# Configure output format
if ($JsonOutput) {
    $lycheeArgs += "--format", "json"
} else {
    $lycheeArgs += "--format", "markdown"
}

# Add output file if specified
if ($OutputFile) {
    $lycheeArgs += "--output", $OutputFile
}

# Skip checking local files if requested
if ($SkipLocalFiles) {
    $lycheeArgs += "--exclude", "^file://"
}

# Add any exclude patterns
foreach ($pattern in $ExcludePatterns) {
    $lycheeArgs += "--exclude", $pattern
}

# Determine which directories to check
$pathsToCheck = @()

if ($Target -eq "all" -or $Target -eq "both") {
    $pathsToCheck += $docsPath
    $pathsToCheck += $wikiPath
} elseif ($Target -eq "main") {
    $pathsToCheck += $docsPath
} elseif ($Target -eq "wiki") {
    $pathsToCheck += $wikiPath
} else {
    # Assume $Target is a specific file or directory path
    $pathsToCheck += $Target
}

# Add paths to check at the end of the args array
$lycheeArgs += $pathsToCheck

# Run lychee with the configured arguments
Write-Host "Checking links with lychee..." -ForegroundColor Cyan
Write-Host "Command: $lycheePath $($lycheeArgs -join ' ')" -ForegroundColor DarkGray

$exitCode = 0
try {
    & $lycheePath $lycheeArgs
    $exitCode = $LASTEXITCODE
} catch {
    Write-Host "Error running lychee: $_" -ForegroundColor Red
    exit 1
}

# Report results
if ($exitCode -eq 0) {
    Write-Host "✅ All links are valid." -ForegroundColor Green
} elseif ($exitCode -eq 2) {
    Write-Host "❌ Some links are broken. Check the output for details." -ForegroundColor Red
} else {
    Write-Host "❓ Lychee encountered an error (exit code: $exitCode)." -ForegroundColor Red
}

exit $exitCode
