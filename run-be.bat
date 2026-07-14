@echo off
echo Khoi dong GymSup Backend API...
cd "%~dp0GymSup-BE"
"C:\Program Files\dotnet\dotnet.exe" run --project GymSupport.API --launch-profile http
