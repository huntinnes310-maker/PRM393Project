[CmdletBinding()]
param(
    [string]$SeedPath,
    [string]$OutputDirectory,
    [int]$Limit = 3,
    [int]$StartAt = 0,
    [string]$Model = "gpt-image-2",
    [ValidateSet("low", "medium", "high")]
    [string]$Quality = "medium",
    [ValidateSet("png", "webp", "jpeg")]
    [string]$OutputFormat = "webp",
    [ValidateRange(0, 100)]
    [int]$OutputCompression = 75,
    [switch]$DryRun,
    [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SeedPath)) {
    $SeedPath = Join-Path $PSScriptRoot "exercises.seed.json"
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot "generated-media\images"
}
if ($Limit -lt 1) {
    throw "Limit must be at least 1."
}
if ($StartAt -lt 0) {
    throw "StartAt cannot be negative."
}
if (-not (Test-Path -LiteralPath $SeedPath)) {
    throw "Seed file not found: $SeedPath"
}

function ConvertTo-Slug([string]$Value) {
    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    return $slug.Trim("-")
}

function Get-ExerciseSpecificCue([string]$ExerciseName) {
    switch ($ExerciseName) {
        "Barbell Bench Press" {
            return "Use a perfectly flat horizontal bench at 0 degrees. Do not use an incline or decline bench."
        }
        "Dumbbell Bench Press" {
            return "Use a perfectly flat horizontal bench at 0 degrees. The athlete holds exactly two dumbbells. Do not use an incline or decline bench."
        }
        "Incline Barbell Press" {
            return "Use an incline bench set around 30 degrees with the athlete's head higher than the hips. Use one barbell, not dumbbells."
        }
        "Incline Dumbbell Press" {
            return "Use an incline bench set around 30 degrees with the athlete's head higher than the hips. The athlete holds exactly two dumbbells."
        }
        "Decline Bench Press" {
            return "Use a decline bench with the athlete's head lower than the hips. Use one barbell, not dumbbells."
        }
        default {
            return "Follow the standard equipment setup and conventional technique for this exact named exercise."
        }
    }
}

$apiKey = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY")
if (-not $DryRun -and [string]::IsNullOrWhiteSpace($apiKey)) {
    throw "OPENAI_API_KEY is missing in this PowerShell session."
}

$seed = Get-Content -Raw -Encoding utf8 -LiteralPath $SeedPath | ConvertFrom-Json
if ($StartAt -ge $seed.Count) {
    throw "StartAt $StartAt is outside the seed list ($($seed.Count) exercises)."
}

$selected = @($seed | Select-Object -Skip $StartAt -First $Limit)
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Write-Host "Selected $($selected.Count) exercise(s), starting at index $StartAt." -ForegroundColor Cyan

$created = 0
$skipped = 0
$failed = 0

foreach ($exercise in $selected) {
    $slug = ConvertTo-Slug $exercise.name
    $extension = if ($OutputFormat -eq "jpeg") { "jpg" } else { $OutputFormat }
    $outputPath = Join-Path $OutputDirectory "$slug.$extension"
    $primaryMuscle = [string]$exercise.primaryMuscle
    $equipment = [string]$exercise.equipment
    $exerciseSpecificCue = Get-ExerciseSpecificCue $exercise.name

    $prompt = @"
Create a realistic, anatomically accurate fitness exercise demonstration image.
Exercise: $($exercise.name).
Primary muscle: $primaryMuscle.
Equipment: $equipment.
$exerciseSpecificCue
Show one adult athlete demonstrating the correct starting or most informative position.
Use a side three-quarter camera angle with the full body and all equipment visible.
Professional bright gym, neutral uncluttered background, realistic photography.
Correct joint alignment, grip, stance, equipment placement, and safe exercise form.
No text, labels, arrows, logos, watermark, collage, split screen, or extra people.
Landscape composition suitable for a mobile fitness application.
"@

    if ((Test-Path -LiteralPath $outputPath) -and -not $Overwrite) {
        Write-Host "SKIP   $($exercise.name) (file exists)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    if ($DryRun) {
        Write-Host "DRYRUN $($exercise.name) -> $outputPath" -ForegroundColor Yellow
        Write-Host $prompt -ForegroundColor DarkGray
        continue
    }

    $body = [ordered]@{
        model = $Model
        prompt = $prompt
        n = 1
        size = "1536x1024"
        quality = $Quality
        output_format = $OutputFormat
        output_compression = $OutputCompression
    } | ConvertTo-Json -Depth 5

    try {
        Write-Host "CREATE $($exercise.name)..." -ForegroundColor Green
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "https://api.openai.com/v1/images/generations" `
            -Headers @{ Authorization = "Bearer $apiKey" } `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($body))

        $base64 = [string]$response.data[0].b64_json
        if ([string]::IsNullOrWhiteSpace($base64)) {
            throw "OpenAI response did not contain b64_json."
        }

        [IO.File]::WriteAllBytes($outputPath, [Convert]::FromBase64String($base64))
        $created++
        Write-Host "SAVED  $outputPath" -ForegroundColor Green
    }
    catch {
        $failed++
        Write-Host "FAIL   $($exercise.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Image summary: created=$created, skipped=$skipped, failed=$failed" -ForegroundColor Cyan
if ($failed -gt 0) {
    exit 1
}
