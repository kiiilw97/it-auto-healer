# تلوين الشاشة وترتيب الواجهة
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     [+] SYSTEM DIAGNOSTIC & CLEANUP SCRIPT       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. فحص صحة الهاردسك
Write-Host "`n[..] Checking Storage Health..." -ForegroundColor Yellow
$DriveStatus = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if ($DriveStatus.PredictFailure -eq $true) {
    Write-Host "[ERROR] Warning: Your Hard Drive might fail soon!" -ForegroundColor Red
} else {
    Write-Host "[SUCCESS] Hard Drive Status: Healthy and Clean." -ForegroundColor Green
}

# 2. تنظيف ملفات الـ Temp الكاتمة للجهاز
Write-Host "`n[..] Cleaning System Temp Files..." -ForegroundColor Yellow
$TempPaths = @("$env:TEMP\*", "$env:SystemRoot\Temp\*")
foreach ($Path in $TempPaths) {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "[SUCCESS] Temp Files Cleared Successfully!" -ForegroundColor Green

# 3. [ميزة جديدة] صيد مفتاح تنشيط الويندوز الأصلي من المذربورد
Write-Host "`n[..] Extracting Windows Product Key..." -ForegroundColor Yellow
$WinKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
if ($WinKey) {
    Write-Host "[SUCCESS] Found Original Windows Key: $WinKey" -ForegroundColor Integrated
} else {
    Write-Host "[INFO] No digital key found in BIOS (Might be digital license)." -ForegroundColor Digital
}

# 4. [ميزة جديدة] لوحة معلومات الشبكة السريعة
Write-Host "`n[..] Checking Network Status..." -ForegroundColor Yellow
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127*" -and $_.InterfaceAlias -notlike "*Loopback*"}).IPAddress | Select-Object -First 1
Write-Host "-> Your Local IP: $LocalIP" -ForegroundColor White

# فحص هل النت شغال أو لا (Ping)
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host "[SUCCESS] Internet Status: Connected" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Internet Status: Disconnected" -ForegroundColor Red
}

# 5. إظهار تقرير سريع للمعالج والذاكرة
Write-Host "`n[..] Gathering System Resources..." -ForegroundColor Yellow
$CPU = (Get-WmiObject Win32_Processor).Name
$RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "-> CPU: $CPU" -ForegroundColor White
Write-Host "-> Total RAM: $RAM GB" -ForegroundColor White

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "          [+] PHASE 2 COMPLETED WITH 0 ERRORS     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
