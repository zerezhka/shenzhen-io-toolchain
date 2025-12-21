# Extract assembly code from Shenzhen I/O solution files (PowerShell version)
# Usage: .\extract-solutions.ps1 <solutions-dir> <output-dir> [game-files-dir]

param(
    [string]$SolutionsDir = "",
    [string]$OutputDir = "tests\extracted-solutions",
    [string]$GameFilesDir = "originalgamefilessteam\Content"
)

$ErrorActionPreference = "Stop"

# Function to map puzzle ID to game file name
function Get-GameFileName {
    param([string]$PuzzleId)
    
    switch ($PuzzleId) {
        "Sz000" { return "security-camera" }
        "Sz001" { return "amplifier" }
        "Sz002" { return "pulse-generator" }
        "Sz003" { return "animated-sign" }
        "Sz004" { return "scorekeeper" }
        "Sz005" { return "harmonic-maximization-engine" }
        "Sz006" { return "infrared-sensor" }
        "Sz007" { return "virtual-reality-buzzer" }
        "Sz008" { return "game-controller" }
        "Sz009" { return "laser-tag" }
        "Sz010" { return "vape-pen" }
        "Sz011" { return "unknown-device" }
        "Sz012" { return "token-machine" }
        "Sz013" { return "sandwich-robot" }
        "Sz014" { return "targeting-laser" }
        "Sz015" { return "haunted-doll" }
        "Sz016" { return "shoes" }
        "Sz017" { return "remote-kill-switch" }
        "Sz018" { return "smart-grid" }
        "Sz019" { return "pocket-i-ching" }
        "Sz020" { return "food-scale" }
        "Sz021" { return "cryptocurrency" }
        "Sz022" { return "sliding-window" }
        "Sz023" { return "vehicle-signal" }
        "Sz024" { return "meat-printer" }
        "Sz025" { return "delay-module" }
        "Sz026" { return "reactor-status" }
        "Sz027" { return "comm-badge" }
        "Sz028" { return "cold-storage" }
        "Sz029" { return "chronometer" }
        "Sz030" { return "cat-feeder" }
        "Sz031" { return "practice-target" }
        "Sz032" { return "harvesting-robot" }
        "Sz033" { return "sushi-robot" }
        "Sz034" { return "reactor-status" }
        "Sz035" { return "computer-interface" }
        "Sz036" { return "scaffold-printer" }
        "Sz037" { return "logic-board" }
        "trailer" { return "trailer" }
        "sandwich-robot-hard" { return "sandwich-robot-hard" }
        "harvesting-robot-hard" { return "harvesting-robot-hard" }
        default { return "" }
    }
}

# If no solutions directory provided, use default Windows location
if ([string]::IsNullOrEmpty($SolutionsDir)) {
    $DefaultPath = Join-Path $env:USERPROFILE "Documents\My Games\SHENZHEN IO"
    
    if (Test-Path $DefaultPath) {
        # Find Steam ID directory
        $SteamDirs = Get-ChildItem -Path $DefaultPath -Directory | Where-Object { $_.Name -match '^\d+$' }
        
        if ($SteamDirs.Count -eq 1) {
            $SolutionsDir = $SteamDirs[0].FullName
            Write-Host "Auto-detected save directory: $SolutionsDir" -ForegroundColor Cyan
        }
        elseif ($SteamDirs.Count -gt 1) {
            Write-Host "Multiple Steam ID directories found. Please specify one:" -ForegroundColor Yellow
            $SteamDirs | ForEach-Object { Write-Host "  $($_.FullName)" }
            exit 1
        }
        else {
            Write-Host "No Steam ID directories found in $DefaultPath" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Error: Default save directory not found: $DefaultPath" -ForegroundColor Red
        Write-Host "Please provide the solutions directory as first argument." -ForegroundColor Yellow
        exit 1
    }
}

if (-not (Test-Path $SolutionsDir)) {
    Write-Host "Error: Solutions directory not found: $SolutionsDir" -ForegroundColor Red
    exit 1
}

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "Extracting solutions from $SolutionsDir to $OutputDir..." -ForegroundColor Green

$solutionCount = 0
$chipCount = 0

# Find all .txt files (solution save files)
$saveFiles = Get-ChildItem -Path $SolutionsDir -Filter "*.txt" -File | Sort-Object Name

foreach ($solutionFile in $saveFiles) {
    $puzzleDir = $solutionFile.Directory.Name
    $solutionName = $solutionFile.BaseName
    
    # Read the save file
    $content = Get-Content -Path $solutionFile.FullName -Raw
    
    # Extract puzzle ID and solution name
    $puzzleId = ""
    $solutionTitle = ""
    
    if ($content -match '\[puzzle\]\s+(\S+)') {
        $puzzleId = $matches[1]
    }
    
    if ($content -match '\[name\]\s+(.+?)[\r\n]') {
        $solutionTitle = $matches[1]
    }
    
    # Map to game file name
    $gameName = ""
    $puzzleTitle = ""
    
    if ($puzzleId) {
        $gameName = Get-GameFileName -PuzzleId $puzzleId
        
        # Try to get puzzle title from game message file
        if ($gameName -and (Test-Path $GameFilesDir)) {
            $messageFile = Join-Path $GameFilesDir "messages.en\$gameName.txt"
            if (Test-Path $messageFile) {
                $messageContent = Get-Content -Path $messageFile -Raw
                if ($messageContent -match 'Subject:\s+(.+?)[\r\n]') {
                    $puzzleTitle = $matches[1]
                }
            }
        }
    }
    
    # Create output directory
    $outDir = Join-Path $OutputDir $puzzleDir
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    
    Write-Host "Processing: $puzzleDir/$solutionName" -ForegroundColor Cyan
    if ($puzzleId) { Write-Host "  Puzzle ID: $puzzleId" -ForegroundColor Gray }
    if ($puzzleTitle) { Write-Host "  Title: $puzzleTitle" -ForegroundColor Gray }
    if ($solutionTitle) { Write-Host "  Solution: $solutionTitle" -ForegroundColor Gray }
    
    # Create metadata file
    if ($puzzleId -or $puzzleTitle) {
        $metadataContent = @"
Puzzle ID: $(if ($puzzleId) { $puzzleId } else { "unknown" })
Puzzle Title: $(if ($puzzleTitle) { $puzzleTitle } else { "Unknown" })
Game File: $(if ($gameName) { $gameName } else { "unknown" })
Solution Name: $(if ($solutionTitle) { $solutionTitle } else { "Untitled" })
Source File: $($solutionFile.Name)
"@
        $metadataContent | Out-File -FilePath (Join-Path $outDir "puzzle-info.txt") -Encoding UTF8
    }
    
    # Parse chips using regex
    $chips = [regex]::Matches($content, '(?s)\[chip\].*?(?=\[chip\]|$)')
    
    $chipNum = 0
    foreach ($chip in $chips) {
        $chipNum++
        $chipContent = $chip.Value
        
        # Extract chip metadata
        $chipType = ""
        $chipX = ""
        $chipY = ""
        $chipCode = ""
        
        if ($chipContent -match '\[type\]\s+(\S+)') {
            $chipType = $matches[1]
        }
        if ($chipContent -match '\[x\]\s+(\S+)') {
            $chipX = $matches[1]
        }
        if ($chipContent -match '\[y\]\s+(\S+)') {
            $chipY = $matches[1]
        }
        if ($chipContent -match '(?s)\[code\]\s*[\r\n]+(.*?)(?:\[|$)') {
            $chipCode = $matches[1]
        }
        
        # Skip NOTE chips
        if ($chipType -eq "NOTE") {
            continue
        }
        
        # Skip if no code
        if ([string]::IsNullOrWhiteSpace($chipCode)) {
            continue
        }
        
        # Process code lines
        $codeLines = $chipCode -split '[\r\n]+' | ForEach-Object {
            $line = $_ -replace '^  ', ''  # Remove leading 2 spaces
            $line = $line -replace '^\d+:', ''  # Remove line number prefix
            $line
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
        # Create header
        $header = @"
# Extracted from: $solutionTitle
"@
        if ($puzzleTitle) {
            $header += "`n# Puzzle: $puzzleTitle"
        }
        $header += "`n# Chip $chipNum`: $chipType @ ($chipX, $chipY)`n"
        
        # Write assembly file
        $filename = "chip{0:D2}_{1}_x{2}_y{3}.asm" -f $chipNum, $chipType, $chipX, $chipY
        $filepath = Join-Path $outDir $filename
        
        $output = $header + ($codeLines -join "`n") + "`n"
        $output | Out-File -FilePath $filepath -Encoding UTF8 -NoNewline
        
        $chipCount++
    }
    
    $solutionCount++
}

Write-Host ""
Write-Host "Extraction complete!" -ForegroundColor Green
Write-Host "Solutions processed: $solutionCount"
Write-Host "Total chips extracted: $chipCount"
Write-Host "Output directory: $OutputDir"
Write-Host ""
Write-Host "To test assembly on all extracted files:" -ForegroundColor Yellow
Write-Host '  Get-ChildItem -Path $OutputDir -Filter "*.asm" -Recurse | ForEach-Object {'
Write-Host '    Write-Host "Testing $($_.Name)..."'
Write-Host '    .\sio.exe assemble $_.FullName -o temp.out'
Write-Host '  }'

