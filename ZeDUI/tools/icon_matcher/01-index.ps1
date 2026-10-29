# Smashicons Library Indexer
# Crawls the Smashicons folder and generates a complete JSON index of all SVG icons
# Output: smashicons-index.json on the Desktop

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Join-Path $scriptDir "Smashicons"
$outputPath = Join-Path $scriptDir "smashicons-index.json"

$categories = @()
$totalIcons = 0

# Get all category folders (skip 'zips')
$categoryFolders = Get-ChildItem -Path $rootPath -Directory | Where-Object { $_.Name -ne "zips" } | Sort-Object Name

foreach ($folder in $categoryFolders) {
    # Extract category name from folder pattern: "12345-category-name"
    $folderName = $folder.Name
    $categoryName = ($folderName -replace '^\d+-', '').Trim()
    $categoryId = ($folderName -replace '-.*$', '').Trim()
    
    # Look for SVG subfolder (pattern: foldername/foldername/svg/)
    $svgPath = Join-Path $folder.FullName "$folderName\svg"
    
    if (-not (Test-Path $svgPath)) {
        # Try flat structure: {folder}/svg/ directly
        $flatSvg = Join-Path $folder.FullName "svg"
        if (Test-Path $flatSvg) {
            $svgPath = $flatSvg
        } else {
            # Try alternate nested structures
            $innerDirs = Get-ChildItem -Path $folder.FullName -Directory
            foreach ($inner in $innerDirs) {
                $tryPath = Join-Path $inner.FullName "svg"
                if (Test-Path $tryPath) {
                    $svgPath = $tryPath
                    break
                }
            }
        }
    }
    
    $icons = @()
    
    if (Test-Path $svgPath) {
        $svgFiles = Get-ChildItem -Path $svgPath -Filter "*.svg" | Sort-Object Name
        
        foreach ($svg in $svgFiles) {
            # Parse filename: "001-descriptive name.svg"
            $fileName = $svg.BaseName
            $iconNumber = ""
            $iconName = $fileName
            
            if ($fileName -match '^(\d+)-(.+)$') {
                $iconNumber = $Matches[1]
                $iconName = $Matches[2]
            }
            
            $icons += @{
                file = $svg.Name
                name = $iconName
                number = $iconNumber
                path = $svg.FullName -replace [regex]::Escape($rootPath + "\"), ""
            }
        }
    }
    
    # Also check for PNG to see total available formats
    $formats = @()
    $innerPath = Join-Path $folder.FullName $folderName
    if (Test-Path $innerPath) {
        $formatDirs = Get-ChildItem -Path $innerPath -Directory
        $formats = $formatDirs | ForEach-Object { $_.Name }
    }
    
    $totalIcons += $icons.Count
    
    $categories += @{
        folder = $folderName
        category = $categoryName
        category_id = $categoryId
        icon_count = $icons.Count
        formats = $formats
        icons = $icons
    }
}

# Build final index
$index = @{
    library = "Smashicons"
    root_path = $rootPath
    generated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    total_categories = $categories.Count
    total_icons = $totalIcons
    categories = $categories
}

# Convert to JSON and save
$json = $index | ConvertTo-Json -Depth 5
$json | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "=== Smashicons Library Index ===" -ForegroundColor Cyan
Write-Host "Categories: $($categories.Count)" -ForegroundColor Green
Write-Host "Total SVG icons: $totalIcons" -ForegroundColor Green
Write-Host "Output: $outputPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Top 10 categories by icon count:" -ForegroundColor Cyan
$categories | Sort-Object { $_.icon_count } -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.category): $($_.icon_count) icons" -ForegroundColor White
}
Write-Host ""
Write-Host "Done. 'Groovy.' - Ash Williams" -ForegroundColor Magenta
