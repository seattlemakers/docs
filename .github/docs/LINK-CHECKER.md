# Link Checker Usage

This repository includes a link checker script that uses [lychee](https://github.com/lycheeverse/lychee) to validate all links in our markdown files. The script is located in the `scripts` directory.

## Basic Usage

```powershell
# Check all links in both main docs and docs.wiki
./scripts/check-links.ps1

# Check only the main docs folder
./scripts/check-links.ps1 -Target main

# Check only the docs.wiki folder
./scripts/check-links.ps1 -Target wiki

# Check a specific file
./scripts/check-links.ps1 -Target ./path/to/file.md
```

## Advanced Options

```powershell
# Output results in JSON format
./scripts/check-links.ps1 -JsonOutput

# Save results to a file
./scripts/check-links.ps1 -OutputFile results.md

# Skip checking local file:// URLs
./scripts/check-links.ps1 -SkipLocalFiles

# Exclude specific URL patterns
./scripts/check-links.ps1 -ExcludePatterns "^https://example.com", "\.pdf$"

# Display verbose output
./scripts/check-links.ps1 -Verbose
```

## Exit Codes

- `0`: All links are valid
- `2`: Some links are broken
- Other: An error occurred during execution

## Requirements

The script requires:
- PowerShell
- Rust and Cargo (to install lychee)

If lychee is not already installed, the script will attempt to install it using Cargo.
