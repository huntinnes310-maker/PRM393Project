[CmdletBinding()]
param(
    [string]$ApiBaseUrl = "https://api.gsfitness.id.vn",
    [Parameter(Mandatory = $true)]
    [string]$AdminEmail,
    [string]$ImageDirectory,
    [int]$Limit = 100,
    [switch]$DryRun,
    [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ImageDirectory)) {
    $ImageDirectory = Join-Path $PSScriptRoot "generated-media\images"
}
if (-not (Test-Path -LiteralPath $ImageDirectory)) {
    throw "Image directory not found: $ImageDirectory"
}
if ($Limit -lt 1) {
    throw "Limit must be at least 1."
}

function ConvertTo-Slug([string]$Value) {
    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    return $slug.Trim("-")
}

function Get-ContentType([string]$Extension) {
    switch ($Extension.ToLowerInvariant()) {
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".webp" { return "image/webp" }
        default { throw "Unsupported image extension: $Extension" }
    }
}

function Get-AdminToken([string]$Email) {
    $securePassword = Read-Host "Admin password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($Email, $securePassword)
    $plainPassword = $credential.GetNetworkCredential().Password
    try {
        $body = @{ email = $Email; password = $plainPassword } | ConvertTo-Json
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "$ApiBaseUrl/api/auth/login" `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($body))
        if ([string]::IsNullOrWhiteSpace([string]$response.token)) {
            throw "Login response did not contain a token."
        }
        return [string]$response.token
    }
    finally {
        $plainPassword = $null
    }
}

function Send-MediaFile([string]$Path, [string]$Token) {
    $client = New-Object System.Net.Http.HttpClient
    $client.DefaultRequestHeaders.Authorization =
        New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $Token)
    $form = New-Object System.Net.Http.MultipartFormDataContent
    try {
        $bytes = [IO.File]::ReadAllBytes($Path)
        $fileContent = [System.Net.Http.ByteArrayContent]::new($bytes)
        $fileContent.Headers.ContentType =
            New-Object System.Net.Http.Headers.MediaTypeHeaderValue((Get-ContentType ([IO.Path]::GetExtension($Path))))
        $form.Add($fileContent, "File", [IO.Path]::GetFileName($Path))

        $response = $client.PostAsync("$ApiBaseUrl/api/media/upload", $form).GetAwaiter().GetResult()
        $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Media upload failed ($([int]$response.StatusCode)): $text"
        }
        return $text | ConvertFrom-Json
    }
    finally {
        $form.Dispose()
        $client.Dispose()
    }
}

Add-Type -AssemblyName System.Net.Http

$token = Get-AdminToken $AdminEmail
$headers = @{ Authorization = "Bearer $token" }
$exercises = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/exercises"
$exerciseBySlug = @{}
foreach ($exercise in $exercises) {
    $exerciseBySlug[(ConvertTo-Slug ([string]$exercise.name))] = $exercise
}

$files = @(Get-ChildItem -LiteralPath $ImageDirectory -File |
    Where-Object { $_.Extension -in ".png", ".jpg", ".jpeg", ".webp" } |
    Sort-Object Name |
    Select-Object -First $Limit)

Write-Host "Found $($files.Count) image(s) to inspect." -ForegroundColor Cyan
$uploaded = 0
$skipped = 0
$failed = 0

foreach ($file in $files) {
    $slug = $file.BaseName
    if (-not $exerciseBySlug.ContainsKey($slug)) {
        Write-Host "FAIL   $($file.Name): no matching exercise" -ForegroundColor Red
        $failed++
        continue
    }

    $exercise = $exerciseBySlug[$slug]
    if (-not $Overwrite -and -not [string]::IsNullOrWhiteSpace([string]$exercise.imageUrl)) {
        Write-Host "SKIP   $($exercise.name) (ImageUrl already set)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    if ($DryRun) {
        Write-Host "DRYRUN $($file.Name) -> $($exercise.name)" -ForegroundColor Yellow
        continue
    }

    try {
        Write-Host "UPLOAD $($file.Name)..." -ForegroundColor Green
        $media = Send-MediaFile $file.FullName $token

        $payload = [ordered]@{
            name = $exercise.name
            equipment = $exercise.equipment
            difficulty = $exercise.difficulty
            description = $exercise.description
            instruction = $exercise.instruction
            safetyNotes = $exercise.safetyNotes
            commonMistakes = $exercise.commonMistakes
            tips = $exercise.tips
            defaultSets = $exercise.defaultSets
            defaultReps = $exercise.defaultReps
            restTimeSeconds = $exercise.restTimeSeconds
            imageUrl = $media.url
            videoUrl = $exercise.videoUrl
            muscleImpacts = @($exercise.muscleImpacts)
        }
        $json = $payload | ConvertTo-Json -Depth 8
        Invoke-RestMethod `
            -Method Put `
            -Uri "$ApiBaseUrl/api/exercises/$($exercise.id)" `
            -Headers $headers `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null

        $exercise.imageUrl = $media.url
        $uploaded++
        Write-Host "UPDATED $($exercise.name)" -ForegroundColor Green
    }
    catch {
        $failed++
        Write-Host "FAIL   $($exercise.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Upload summary: uploaded=$uploaded, skipped=$skipped, failed=$failed" -ForegroundColor Cyan
if ($failed -gt 0) {
    exit 1
}
