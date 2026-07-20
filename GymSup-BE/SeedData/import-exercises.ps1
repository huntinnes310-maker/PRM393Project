[CmdletBinding()]
param(
    [string]$ApiBaseUrl = "https://api.gsfitness.id.vn",
    [string]$AdminEmail,
    [string]$MusclesPath,
    [string]$SeedPath,
    [switch]$UpdateExisting,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($MusclesPath)) {
    $MusclesPath = Join-Path $PSScriptRoot "..\..\muscles.json"
}
if ([string]::IsNullOrWhiteSpace($SeedPath)) {
    $SeedPath = Join-Path $PSScriptRoot "exercises.seed.json"
}

function Normalize-Name([string]$Value) {
    if ($null -eq $Value) { return "" }
    return $Value.Trim().ToLowerInvariant()
}

function Get-AdminToken {
    param([string]$Email)

    if ([string]::IsNullOrWhiteSpace($Email)) {
        throw "AdminEmail is required unless DryRun is used."
    }

    $securePassword = Read-Host "Admin password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($Email, $securePassword)
    $plainPassword = $credential.GetNetworkCredential().Password

    try {
        $loginBody = @{
            email = $Email
            password = $plainPassword
        } | ConvertTo-Json

        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "$ApiBaseUrl/api/auth/login" `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($loginBody))

        $token = $response.token
        if ([string]::IsNullOrWhiteSpace($token)) {
            throw "Login response did not contain a token."
        }

        return $token
    }
    finally {
        $plainPassword = $null
    }
}

if (-not (Test-Path -LiteralPath $MusclesPath)) {
    throw "Muscles file not found: $MusclesPath"
}
if (-not (Test-Path -LiteralPath $SeedPath)) {
    throw "Exercise seed file not found: $SeedPath"
}

$muscles = Get-Content -Raw -Encoding utf8 -LiteralPath $MusclesPath | ConvertFrom-Json
$seed = Get-Content -Raw -Encoding utf8 -LiteralPath $SeedPath | ConvertFrom-Json

$muscleByName = @{}
foreach ($muscle in $muscles) {
    $key = Normalize-Name $muscle.name
    if ($muscleByName.ContainsKey($key)) {
        throw "Duplicate muscle name after normalization: $($muscle.name)"
    }
    $muscleByName[$key] = $muscle
}

$validationErrors = @()
foreach ($exercise in $seed) {
    $requiredMuscles = @($exercise.primaryMuscle) + @($exercise.secondaryMuscles)
    foreach ($muscleName in $requiredMuscles) {
        if (-not $muscleByName.ContainsKey((Normalize-Name $muscleName))) {
            $validationErrors += "$($exercise.name): unknown muscle '$muscleName'"
        }
    }
}

if ($validationErrors.Count -gt 0) {
    $validationErrors | ForEach-Object { Write-Error $_ }
    throw "Seed validation failed with $($validationErrors.Count) error(s)."
}

Write-Host "Validated $($seed.Count) exercises against $($muscles.Count) muscles." -ForegroundColor Green

if ($DryRun) {
    Write-Host "Dry run complete. No API requests were sent." -ForegroundColor Cyan
    exit 0
}

$token = Get-AdminToken -Email $AdminEmail
$headers = @{ Authorization = "Bearer $token" }
$existingExercises = @(Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/exercises")
$existingNames = @{}
foreach ($existing in $existingExercises) {
    $existingNames[(Normalize-Name $existing.name)] = $existing
}

$created = 0
$updated = 0
$skipped = 0
$failed = 0

# Keep localized copy as JSON Unicode escapes so Windows PowerShell 5 can load
# this UTF-8 script correctly even when the file has no byte-order mark (BOM).
$localizedCopy = ('{' +
    '"descriptionPrefix":" l\u00e0 b\u00e0i t\u1eadp t\u1eadp trung ch\u1ee7 y\u1ebfu v\u00e0o ",' +
    '"instruction":"Thi\u1ebft l\u1eadp d\u1ee5ng c\u1ee5 v\u00e0 t\u01b0 th\u1ebf \u1ed5n \u0111\u1ecbnh. Th\u1ef1c hi\u1ec7n chuy\u1ec3n \u0111\u1ed9ng ch\u1eadm, c\u00f3 ki\u1ec3m so\u00e1t trong bi\u00ean \u0111\u1ed9 kh\u00f4ng g\u00e2y \u0111au; th\u1edf ra \u1edf pha g\u1eafng s\u1ee9c v\u00e0 h\u00edt v\u00e0o khi tr\u1edf v\u1ec1.",' +
    '"safetyNotes":"\u01afu ti\u00ean k\u1ef9 thu\u1eadt tr\u01b0\u1edbc m\u1ee9c t\u1ea1. D\u1eebng b\u00e0i t\u1eadp n\u1ebfu \u0111au nh\u00f3i, ch\u00f3ng m\u1eb7t ho\u1eb7c m\u1ea5t ki\u1ec3m so\u00e1t t\u01b0 th\u1ebf.",' +
    '"commonMistakes":"D\u00f9ng m\u1ee9c t\u1ea1 qu\u00e1 n\u1eb7ng, th\u1ef1c hi\u1ec7n qu\u00e1 nhanh, n\u00edn th\u1edf ho\u1eb7c \u0111\u00e1nh \u0111\u1ed5i t\u01b0 th\u1ebf \u0111\u1ec3 ho\u00e0n th\u00e0nh s\u1ed1 l\u1ea7n l\u1eb7p.",' +
    '"tips":"B\u1eaft \u0111\u1ea7u nh\u1eb9, gi\u1eef nh\u1ecbp \u1ed5n \u0111\u1ecbnh v\u00e0 t\u0103ng t\u1ea3i d\u1ea7n khi ho\u00e0n th\u00e0nh to\u00e0n b\u1ed9 s\u1ed1 l\u1ea7n l\u1eb7p v\u1edbi k\u1ef9 thu\u1eadt t\u1ed1t."' +
    '}') | ConvertFrom-Json

foreach ($exercise in $seed) {
    $exerciseKey = Normalize-Name $exercise.name
    $existingExercise = $null
    if ($existingNames.ContainsKey($exerciseKey)) {
        $existingExercise = $existingNames[$exerciseKey]
    }

    if ($null -ne $existingExercise -and -not $UpdateExisting) {
        Write-Host "SKIP  $($exercise.name)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    $secondaryMuscles = @($exercise.secondaryMuscles)
    $impacts = @()

    if ($secondaryMuscles.Count -eq 0) {
        $impacts += [ordered]@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 100
        }
    }
    elseif ($secondaryMuscles.Count -eq 1) {
        $impacts += [ordered]@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 70
        }
        $impacts += [ordered]@{
            muscleId = $muscleByName[(Normalize-Name $secondaryMuscles[0])].id
            percentage = 30
        }
    }
    else {
        $impacts += [ordered]@{
            muscleId = $muscleByName[(Normalize-Name $exercise.primaryMuscle)].id
            percentage = 60
        }
        foreach ($secondaryMuscle in $secondaryMuscles) {
            $impacts += [ordered]@{
                muscleId = $muscleByName[(Normalize-Name $secondaryMuscle)].id
                percentage = 20
            }
        }
    }

    $primaryDisplayName = $exercise.primaryMuscle.Trim()
    $payload = [ordered]@{
        name = $exercise.name
        equipment = $exercise.equipment
        difficulty = $exercise.difficulty
        description = "$($exercise.name) là bài tập tập trung chủ yếu vào $primaryDisplayName."
        instruction = "Thiết lập dụng cụ và tư thế ổn định. Thực hiện chuyển động chậm, có kiểm soát trong biên độ không gây đau; thở ra ở pha gắng sức và hít vào khi trở về."
        safetyNotes = "Ưu tiên kỹ thuật trước mức tạ. Dừng bài tập nếu đau nhói, chóng mặt hoặc mất kiểm soát tư thế."
        commonMistakes = "Dùng mức tạ quá nặng, thực hiện quá nhanh, nín thở hoặc đánh đổi tư thế để hoàn thành số lần lặp."
        tips = "Bắt đầu nhẹ, giữ nhịp ổn định và tăng tải dần khi hoàn thành toàn bộ số lần lặp với kỹ thuật tốt."
        defaultSets = [int]$exercise.sets
        defaultReps = [string]$exercise.reps
        restTimeSeconds = [int]$exercise.rest
        imageUrl = if ($null -ne $existingExercise) { [string]$existingExercise.imageUrl } else { "" }
        videoUrl = if ($null -ne $existingExercise) { [string]$existingExercise.videoUrl } else { "" }
        muscleImpacts = $impacts
    }

    # Assign the Vietnamese copy here using known-good UTF-8 text. These values
    # also overwrite data produced by older versions of this script.
    $payload.description = "$($exercise.name) là bài tập tập trung chủ yếu vào $primaryDisplayName."
    $payload.instruction = "Thiết lập dụng cụ và tư thế ổn định. Thực hiện chuyển động chậm, có kiểm soát trong biên độ không gây đau; thở ra ở pha gắng sức và hít vào khi trở về."
    $payload.safetyNotes = "Ưu tiên kỹ thuật trước mức tạ. Dừng bài tập nếu đau nhói, chóng mặt hoặc mất kiểm soát tư thế."
    $payload.commonMistakes = "Dùng mức tạ quá nặng, thực hiện quá nhanh, nín thở hoặc đánh đổi tư thế để hoàn thành số lần lặp."
    $payload.tips = "Bắt đầu nhẹ, giữ nhịp ổn định và tăng tải dần khi hoàn thành toàn bộ số lần lặp với kỹ thuật tốt."

    $payload.description = "$($exercise.name)$($localizedCopy.descriptionPrefix)$primaryDisplayName."
    $payload.instruction = $localizedCopy.instruction
    $payload.safetyNotes = $localizedCopy.safetyNotes
    $payload.commonMistakes = $localizedCopy.commonMistakes
    $payload.tips = $localizedCopy.tips

    $json = $payload | ConvertTo-Json -Depth 8

    try {
        $method = if ($null -ne $existingExercise) { "Put" } else { "Post" }
        $uri = if ($null -ne $existingExercise) {
            "$ApiBaseUrl/api/exercises/$($existingExercise.id)"
        } else {
            "$ApiBaseUrl/api/exercises"
        }

        Invoke-RestMethod `
            -Method $method `
            -Uri $uri `
            -Headers $headers `
            -ContentType "application/json; charset=utf-8" `
            -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null

        if ($null -ne $existingExercise) {
            $updated++
            Write-Host "UPDATE $($exercise.name)" -ForegroundColor Cyan
        }
        else {
            $created++
            Write-Host "CREATE $($exercise.name)" -ForegroundColor Green
        }
    }
    catch {
        $failed++
        Write-Host "FAIL  $($exercise.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Import summary: created=$created, updated=$updated, skipped=$skipped, failed=$failed" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
}
