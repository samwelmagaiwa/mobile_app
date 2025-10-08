# PowerShell Script to Fix Common Flutter Linting Issues
# This script addresses:
# 1. prefer_double_quotes - Convert single quotes to double quotes
# 2. eol_at_end_of_file - Add missing newlines at end of files
# 3. Remove unused local variables where safe

Write-Host "Starting Flutter Linting Fixes..." -ForegroundColor Green

# Get all Dart files in the project
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

Write-Host "Found $($dartFiles.Count) Dart files to process..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    Write-Host "Processing: $($file.FullName)" -ForegroundColor Cyan
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Skip if file is empty
    if ([string]::IsNullOrWhiteSpace($content)) {
        continue
    }
    
    # 1. Fix prefer_double_quotes - Convert single quotes to double quotes
    # Be careful with quotes inside strings and comments
    
    # Pattern for import statements with single quotes
    $content = $content -replace "import\s+'([^']+)';", 'import "$1";'
    
    # Pattern for simple string literals (not containing double quotes)
    $content = $content -replace "(?<!\\)'([^'\\]*(?:\\.[^'\\]*)*)'(?!\s*[:])", '"$1"'
    
    # Pattern for map/object keys with single quotes
    $content = $content -replace "(\s*)'([^']+)'(\s*:\s*)", '$1"$2"$3'
    
    # 2. Fix eol_at_end_of_file - Ensure file ends with newline
    if (-not $content.EndsWith("`n")) {
        $content = $content.TrimEnd() + "`n"
    }
    
    # 3. Remove obvious unused variables (be conservative)
    # Remove unused 'chartData' variable specifically
    $content = $content -replace "(?m)^\s*final\s+\w+\s+chartData\s*=.*?;.*?$", ""
    $content = $content -replace "(?m)^\s*var\s+chartData\s*=.*?;.*?$", ""
    $content = $content -replace "(?m)^\s*Map<String,\s*dynamic>\s+chartData\s*=.*?;.*?$", ""
    
    # Only write if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  ✓ Fixed: $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "  - No changes: $($file.Name)" -ForegroundColor Gray
    }
}

Write-Host "Linting fixes complete! Running flutter analyze..." -ForegroundColor Green

# Run flutter analyze to check results
flutter analyze
