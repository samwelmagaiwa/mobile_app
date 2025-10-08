# Fix broken string literals caused by overly aggressive quote conversion
Write-Host "Fixing broken string literals..." -ForegroundColor Green

# Function to fix common broken patterns
function Fix-BrokenStrings {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $originalContent = $content
    
    # Fix common broken patterns
    $content = $content -replace '\.replaceAll\(([^,]+), \""\)', '.replaceAll($1, "")'
    $content = $content -replace '\.replaceAll\(([^,]+), \"\'\'\)', '.replaceAll($1, "")'
    $content = $content -replace '\.endsWith\(\"(\w+)\"\"\)', '.endsWith("$1")'
    $content = $content -replace '\.startsWith\(\"(\w+)\"\"\)', '.startsWith("$1")'
    $content = $content -replace 'case \"([^"]+)\"\":', 'case "$1":'
    $content = $content -replace 'return \"([^"]+)\"\"', 'return "$1"'
    
    # Fix specific patterns found in analysis
    $content = $content -replace '\\""\)', '"")'
    $content = $content -replace '\\"\'', '""'
    
    # Fix malformed string constants
    $content = $content -replace 'const String \w+ = \"[^"]*$', { $matches[0] + '";' }
    
    if ($content -ne $originalContent) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  Fixed: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        return $true
    }
    return $false
}

# Get files with broken strings
$brokenFiles = @(
    "lib\models\device.dart",
    "lib\models\login_response.dart", 
    "lib\models\reminder.dart",
    "lib\models\transaction.dart",
    "lib\providers\auth_provider.dart",
    "lib\providers\transaction_provider.dart",
    "lib\screens\admin\drivers_management_screen.dart",
    "lib\screens\admin\payments_management_screen.dart",
    "lib\screens\admin\vehicles_management_screen.dart",
    "lib\utils\api_helpers.dart",
    "lib\utils\type_helpers.dart",
    "lib\utils\validation.dart"
)

$fixedCount = 0
foreach ($file in $brokenFiles) {
    if (Test-Path $file) {
        if (Fix-BrokenStrings -FilePath $file) {
            $fixedCount++
        }
    }
}

Write-Host "Fixed $fixedCount files." -ForegroundColor Green