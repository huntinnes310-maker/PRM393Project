param(
    [string]$AdminEmail = "nkg109204@gmail.com",
    [string]$AdminPassword,
    [string]$ApiBaseUrl = "http://localhost:5028"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
    throw "Vui long truyen -AdminPassword 'matkhaucuaban'"
}

# Đăng nhập lấy token
Write-Host "Dang nhap..." -ForegroundColor Cyan
$loginBytes = [System.Text.Encoding]::UTF8.GetBytes("{`"email`":`"$AdminEmail`",`"password`":`"$AdminPassword`"}")
$loginResp = Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl/api/auth/login" -ContentType "application/json; charset=utf-8" -Body $loginBytes
$token = $loginResp.token
$headers = @{ Authorization = "Bearer $token" }
Write-Host "Dang nhap thanh cong!" -ForegroundColor Green

# Lấy danh sách muscles
Write-Host "Lay danh sach nhom co..." -ForegroundColor Cyan
$musclesResp = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/muscles"
$muscles = $musclesResp.value
Write-Host "Tim thay $($muscles.Count) nhom co" -ForegroundColor Green

# Tạo lookup table theo tên normalize
$muscleMap = @{}
foreach ($m in $muscles) {
    $key = $m.name.Trim().ToLowerInvariant()
    $muscleMap[$key] = $m.id
}

# Lấy danh sách exercises hiện tại
Write-Host "Lay danh sach bai tap hien tai..." -ForegroundColor Cyan
$exResp = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/api/exercises"
$existingList = $exResp.value
$existingMap = @{}
foreach ($ex in $existingList) {
    if ($null -ne $ex.name -and $ex.name -ne "") {
        $existingMap[$ex.name.Trim().ToLowerInvariant()] = $ex
    }
}
# Bài tập id=null name thì vào list "empty" để update sau
$emptyExercises = @($existingList | Where-Object { $null -eq $_.name -or $_.name -eq "" })
Write-Host "Tim thay $($existingList.Count) exercises trong DB ($($emptyExercises.Count) chua co data)" -ForegroundColor Green

# Đọc seed data
$seedPath = Join-Path $PSScriptRoot "GymSup-BE\SeedData\exercises.seed.json"
$seed = Get-Content -Raw -Encoding UTF8 -Path $seedPath | ConvertFrom-Json
Write-Host "Doc $($seed.Count) exercises tu seed file" -ForegroundColor Green

function Get-MuscleId([string]$Name) {
    $key = $Name.Trim().ToLowerInvariant()
    if ($muscleMap.ContainsKey($key)) { return $muscleMap[$key] }
    foreach ($k in $muscleMap.Keys) {
        $minLen = [Math]::Min(8, [Math]::Min($key.Length, $k.Length))
        if ($minLen -gt 0 -and $k.Substring(0,$minLen) -eq $key.Substring(0,$minLen)) {
            return $muscleMap[$k]
        }
    }
    Write-Warning "Khong tim thay muscle: '$Name'"
    return $null
}

$created = 0; $updated = 0; $failed = 0
$emptyIndex = 0

foreach ($exercise in $seed) {
    try {
        $primaryId = Get-MuscleId $exercise.primaryMuscle
        if ($null -eq $primaryId) { $failed++; continue }

        $secMuscles = @($exercise.secondaryMuscles | Where-Object { $_ -ne $null -and $_ -ne "" })
        $impacts = @()

        if ($secMuscles.Count -eq 0) {
            $impacts = @(@{ muscleId = $primaryId; percentage = 100 })
        } elseif ($secMuscles.Count -eq 1) {
            $secId = Get-MuscleId $secMuscles[0]
            $impacts = @(@{ muscleId = $primaryId; percentage = 70 }, @{ muscleId = $secId; percentage = 30 })
        } else {
            $impacts = @(@{ muscleId = $primaryId; percentage = 60 })
            foreach ($sec in $secMuscles) {
                $secId = Get-MuscleId $sec
                if ($null -ne $secId) { $impacts += @{ muscleId = $secId; percentage = 20 } }
            }
        }

        $primaryDisplayName = $exercise.primaryMuscle.Trim()
        $payload = @{
            name            = $exercise.name
            equipment       = $exercise.equipment
            difficulty      = $exercise.difficulty
            description     = "$($exercise.name) la bai tap tap trung chu yeu vao $primaryDisplayName."
            instruction     = "Thiet lap dung cu va tu the on dinh. Thuc hien chuyen dong cham, co kiem soat; tho ra o pha gang suc va hit vao khi tro ve."
            safetyNotes     = "Uu tien ky thuat truoc muc ta. Dung bai tap neu dau nhoi, chong mat hoac mat kiem soat tu the."
            commonMistakes  = "Dung muc ta qua nang, thuc hien qua nhanh, nin tho hoac danh doi tu the de hoan thanh so lan lap."
            tips            = "Bat dau nhe, giu nhip on dinh va tang tai dan khi hoan thanh toan bo so lan lap voi ky thuat tot."
            defaultSets     = [int]$exercise.sets
            defaultReps     = [string]$exercise.reps
            restTimeSeconds = [int]$exercise.rest
            imageUrl        = ""
            videoUrl        = ""
            muscleImpacts   = $impacts
        }

        $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 8 -Compress))

        $key = $exercise.name.Trim().ToLowerInvariant()
        $existing = if ($existingMap.ContainsKey($key)) { $existingMap[$key] } else { $null }

        if ($null -ne $existing) {
            # Cập nhật exercise đã có tên
            Invoke-RestMethod -Method Put -Uri "$ApiBaseUrl/api/exercises/$($existing.id)" -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBytes | Out-Null
            Write-Host "UPDATE $($exercise.name)" -ForegroundColor Cyan
            $updated++
        } elseif ($emptyIndex -lt $emptyExercises.Count) {
            # Điền vào slot exercise rỗng
            $emptyEx = $emptyExercises[$emptyIndex]
            $emptyIndex++
            Invoke-RestMethod -Method Put -Uri "$ApiBaseUrl/api/exercises/$($emptyEx.id)" -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBytes | Out-Null
            Write-Host "FILL  $($exercise.name)" -ForegroundColor Yellow
            $updated++
        } else {
            # Tạo mới
            Invoke-RestMethod -Method Post -Uri "$ApiBaseUrl/api/exercises" -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBytes | Out-Null
            Write-Host "CREATE $($exercise.name)" -ForegroundColor Green
            $created++
        }
    } catch {
        Write-Host "FAIL  $($exercise.name): $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=== KET QUA IMPORT ===" -ForegroundColor White
Write-Host "Tao moi: $created | Cap nhat: $updated | Loi: $failed" -ForegroundColor Cyan
