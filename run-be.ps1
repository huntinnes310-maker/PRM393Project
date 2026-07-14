Write-Host "Khoi dong GymSup Backend API..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\GymSup-BE"
& "C:\Program Files\dotnet\dotnet.exe" run --project GymSupport.API --launch-profile http
