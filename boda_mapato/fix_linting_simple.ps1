# Simple PowerShell Script to Fix Common Flutter Linting Issues
Write-Host "Starting Flutter Linting Fixes..." -ForegroundColor Green

# Get all Dart files in the project
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

Write-Host "Found $($dartFiles.Count) Dart files to process..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Skip if file is empty
    if ([string]::IsNullOrWhiteSpace($content)) {
        continue
    }
    
    # 1. Fix import statements - Convert single quotes to double quotes
    $content = $content -replace "import '([^']+)';", 'import "$1";'
    
    # 2. Fix simple string literals
    $content = $content -replace "'([^']+)'", '"$1"'
    
    # 3. Fix eol_at_end_of_file - Ensure file ends with newline
    if (-not $content.EndsWith("`n")) {
        $content = $content.TrimEnd() + "`n"
    }
    
    # Only write if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "  No changes: $($file.Name)" -ForegroundColor Gray
    }
}

Write-Host "Linting fixes complete!" -ForegroundColor Green