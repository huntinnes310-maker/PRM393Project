[CmdletBinding()]
param(
    [string]$ExerciseName = "Barbell Bench Press",
    [string]$ApiBaseUrl = "https://api.gsfitness.xyz",
    [string]$SeedPath,
    [string]$OutputDirectory,
    [ValidateSet("sora-2", "sora-2-pro")]
    [string]$Model = "sora-2",
    [ValidateSet("1280x720", "720x1280")]
    [string]$Size = "1280x720",
    [ValidateSet(4, 8, 12, 16, 20)]
    [int]$Seconds = 4,
    [int]$PollSeconds = 15,
    [int]$MaxWaitMinutes = 30,
    [switch]$DryRun,
    [switch]$ConfirmCost,
    [switch]$NoImageReference,
    [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SeedPath)) {
    $SeedPath = Join-Path $PSScriptRoot "exercises.seed.json"
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot "generated-media\videos"
}
if (-not (Test-Path -LiteralPath $SeedPath)) {
    throw "Seed file not found: $SeedPath"
}
if ($PollSeconds -lt 10) {
    throw "PollSeconds must be at least 10."
}

function ConvertTo-Slug([string]$Value) {
    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    return $slug.Trim("-")
}

function Get-ExerciseCue([string]$Name) {
    switch ($Name) {
        "Barbell Bench Press" {
            return "Use a perfectly flat bench at 0 degrees. Feet stay firmly planted. Use one barbell with a safe medium grip. Lower the bar under control toward the mid chest, then press to full extension without bouncing or excessive back arch."
        }
        "Dumbbell Bench Press" {
            return "Use a perfectly flat bench at 0 degrees and exactly two dumbbells. Feet stay firmly planted. Lower both dumbbells under control, then press evenly without excessive back arch."
        }
        "Incline Barbell Press" {
            return "Use an incline bench around 30 degrees and one barbell. Lower toward the upper chest and press under control."
        }
        default {
            return "Demonstrate the conventional safe technique for this exact exercise with controlled tempo and correct joint alignment."
        }
    }
}

function Add-StringPart($Form, [string]$Name, [string]$Value) {
    $part = [System.Net.Http.StringContent]::new($Value, [Text.Encoding]::UTF8)
    $Form.Add($part, $Name)
}

Add-Type -AssemblyName System.Net.Http

$seed = Get-Content -Raw -Encoding utf8 -LiteralPath $SeedPath | ConvertFrom-Json
$exercise = $seed | Where-Object {
    [string]::Equals([string]$_.name, $ExerciseName, [StringComparison]::OrdinalIgnoreCase)
} | Select-Object -First 1
if ($null -eq $exercise) {
    throw "Exercise not found in seed: $ExerciseName"
}

$primaryMuscle = ([string]$exercise.primaryMuscle).Trim()
$secondaryMuscles = @($exercise.secondaryMuscles | ForEach-Object { ([string]$_).Trim() })
$secondaryText = if ($secondaryMuscles.Count -gt 0) {
    $secondaryMuscles -join ", "
} else {
    "none"
}
$cue = Get-ExerciseCue ([string]$exercise.name)
$slug = ConvertTo-Slug ([string]$exercise.name)
$outputPath = Join-Path $OutputDirectory "$slug.mp4"

$referenceImageUrl = $null
if (-not $NoImageReference) {
    $catalog = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/exercises"
    $catalogExercise = $catalog | Where-Object {
        [string]::Equals([string]$_.name, $ExerciseName, [StringComparison]::OrdinalIgnoreCase)
    } | Select-Object -First 1
    $sourceImageUrl = [string]$catalogExercise.imageUrl
    if ([string]::IsNullOrWhiteSpace($sourceImageUrl)) {
        throw "Exercise '$ExerciseName' does not have an ImageUrl in the backend."
    }

    if ($sourceImageUrl -match 'res\.cloudinary\.com/.+/image/upload/') {
        $dimensions = $Size.Split('x')
        $width = $dimensions[0]
        $height = $dimensions[1]
        $transform = "c_pad,w_$width,h_$height,b_rgb:111827"
        $referenceImageUrl = $sourceImageUrl -replace '/upload/', "/upload/$transform/"
    }
    else {
        throw "Image reference must currently be a Cloudinary URL so it can be resized exactly to $Size."
    }
}

$visualStyle = if ($null -ne $referenceImageUrl) {
@"
Use the supplied image as the exact first frame and visual reference.
Preserve the same athlete, face, body proportions, clothing, equipment, background, lighting, and camera angle.
Add a translucent bright red anatomical glow over the primary muscle ($primaryMuscle).
Add a softer orange-red anatomical glow over the secondary muscles ($secondaryText).
The glows must remain accurately attached to the correct body regions throughout the motion.
"@
} else {
@"
Use one polished, anatomically proportioned adult fitness mannequin with a smooth dark graphite body surface.
Render the primary muscle ($primaryMuscle) as a bright red anatomical muscle group.
Render the secondary muscles ($secondaryText) as softer orange-red anatomical muscle groups.
"@
}

$prompt = @"
Create a premium commercial-quality 3D anatomical fitness animation for a modern mobile exercise app.
Exercise: $($exercise.name).
Equipment: $($exercise.equipment).
$cue
Show exactly one slow, controlled, complete repetition from start to finish.
$visualStyle
Visual style: high-end professional fitness visualization with realistic joints and stable anatomy.
Static side three-quarter camera. Full body and all equipment remain visible.
Stable lighting. End in a pose that can loop smoothly back to the first frame.
Maintain the same face, body proportions, equipment geometry, and camera for every frame.
No text, captions, labels, arrows, logos, watermark, camera cuts, extra people, extra limbs, deformed joints, or extra equipment.
Silent video.
"@

Write-Host "Exercise: $($exercise.name)" -ForegroundColor Cyan
Write-Host "Primary:  $primaryMuscle" -ForegroundColor Cyan
Write-Host "Secondary: $secondaryText" -ForegroundColor Cyan
if ($null -ne $referenceImageUrl) {
    Write-Host "Reference: $referenceImageUrl" -ForegroundColor Cyan
}
Write-Host "Output:    $outputPath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN - no API request was sent." -ForegroundColor Yellow
    Write-Host $prompt -ForegroundColor DarkGray
    exit 0
}
if (-not $ConfirmCost) {
    throw "Video generation incurs API cost. Re-run with -ConfirmCost after reviewing -DryRun."
}
if ((Test-Path -LiteralPath $outputPath) -and -not $Overwrite) {
    throw "Video already exists: $outputPath. Use -Overwrite to replace it."
}

$apiKey = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY")
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "OPENAI_API_KEY is missing in this PowerShell session."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$client = [System.Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromMinutes($MaxWaitMinutes + 5)
$client.DefaultRequestHeaders.Authorization =
    [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $apiKey)

try {
    $requestContent = $null
    try {
        if ($null -ne $referenceImageUrl) {
            $requestBody = [ordered]@{
                model = $Model
                prompt = $prompt
                size = $Size
                seconds = [string]$Seconds
                input_reference = @{ image_url = $referenceImageUrl }
            } | ConvertTo-Json -Depth 6
            $requestContent = [System.Net.Http.StringContent]::new(
                $requestBody,
                [Text.Encoding]::UTF8,
                "application/json"
            )
        }
        else {
            $requestContent = [System.Net.Http.MultipartFormDataContent]::new()
            Add-StringPart $requestContent "prompt" $prompt
            Add-StringPart $requestContent "model" $Model
            Add-StringPart $requestContent "size" $Size
            Add-StringPart $requestContent "seconds" ([string]$Seconds)
        }

        Write-Host "Submitting video generation job..." -ForegroundColor Green
        $createResponse = $client.PostAsync("https://api.openai.com/v1/videos", $requestContent).GetAwaiter().GetResult()
        $createText = $createResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $createResponse.IsSuccessStatusCode) {
            throw "Video creation failed ($([int]$createResponse.StatusCode)): $createText"
        }
        $video = $createText | ConvertFrom-Json
    }
    finally {
        if ($null -ne $requestContent) {
            $requestContent.Dispose()
        }
    }

    $videoId = [string]$video.id
    if ([string]::IsNullOrWhiteSpace($videoId)) {
        throw "Create response did not contain a video id."
    }
    Write-Host "Job id: $videoId" -ForegroundColor Cyan

    $deadline = [DateTime]::UtcNow.AddMinutes($MaxWaitMinutes)
    while ($video.status -in "queued", "in_progress") {
        if ([DateTime]::UtcNow -ge $deadline) {
            throw "Timed out waiting for video $videoId. The job may still be running."
        }
        $progress = if ($null -ne $video.progress) { $video.progress } else { 0 }
        Write-Host "Status: $($video.status), progress: $progress%"
        Start-Sleep -Seconds $PollSeconds

        $statusResponse = $client.GetAsync("https://api.openai.com/v1/videos/$videoId").GetAwaiter().GetResult()
        $statusText = $statusResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $statusResponse.IsSuccessStatusCode) {
            throw "Status request failed ($([int]$statusResponse.StatusCode)): $statusText"
        }
        $video = $statusText | ConvertFrom-Json
    }

    if ($video.status -ne "completed") {
        $errorMessage = if ($null -ne $video.error) { $video.error.message } else { "Unknown error" }
        throw "Video job ended with status '$($video.status)': $errorMessage"
    }

    Write-Host "Downloading completed MP4..." -ForegroundColor Green
    $contentResponse = $client.GetAsync("https://api.openai.com/v1/videos/$videoId/content").GetAwaiter().GetResult()
    if (-not $contentResponse.IsSuccessStatusCode) {
        $errorText = $contentResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        throw "Video download failed ($([int]$contentResponse.StatusCode)): $errorText"
    }
    $bytes = $contentResponse.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    [IO.File]::WriteAllBytes($outputPath, $bytes)
    Write-Host "SAVED $outputPath" -ForegroundColor Green
}
finally {
    $client.Dispose()
}
