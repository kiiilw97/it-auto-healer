# تلوين الشاشة وترتيب الواجهة المحلية
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     [+] SYSTEM DIAGNOSTIC & CLEANUP SCRIPT       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# بيانات التيليجرام الخاصة بك
$BotToken = "8845124533:AAFOyBL62IdyNsfxTJXzYoNtxVdvXAbhi-A"
$ChatID   = "1778953224"

# 1. فحص صحة الهاردسك
Write-Host "`n[..] Checking Storage Health..." -ForegroundColor Yellow
$DriveStatus = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if ($DriveStatus.PredictFailure -eq $true) {
    $HddReport = "🚨 WARNING: Hard Drive Failure Predicted!"
    Write-Host "[ERROR] $HddReport" -ForegroundColor Red
} else {
    $HddReport = "✅ Healthy and Clean"
    Write-Host "[SUCCESS] Hard Drive Status: $HddReport" -ForegroundColor Green
}

# 2. تنظيف ملفات الـ Temp الكاتمة للجهاز
Write-Host "`n[..] Cleaning System Temp Files..." -ForegroundColor Yellow
$TempPaths = @("$env:TEMP\*", "$env:SystemRoot\Temp\*")
foreach ($Path in $TempPaths) {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "[SUCCESS] Temp Files Cleared Successfully!" -ForegroundColor Green

# 3. تنظيف مخلفات التحديثات الآمن
Write-Host "`n[..] Cleaning Windows Update Cache Safely..." -ForegroundColor Yellow
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

$UpdatePath = "$env:SystemRoot\SoftwareDistribution\Download"
$UpdateFiles = Get-ChildItem $UpdatePath -Recurse -ErrorAction SilentlyContinue
if ($UpdateFiles) {
    $SizeBefore = ($UpdateFiles | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    $SavedMB = [Math]::Round($SizeBefore / 1MB, 2)
} else {
    $SavedMB = 0
}

Remove-Item -Path "$UpdatePath\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
Write-Host "[SUCCESS] Windows Update Cache Cleaned ($SavedMB MB Cleared)!" -ForegroundColor Green

# 4. [تحديث جذري] التثبيت الصامت الذكي بالفحص عبر الـ Registry
Write-Host "`n[..] Starting Smart Software Installer..." -ForegroundColor Yellow

$Apps = @(
    @{ Name = "Google Chrome"; ID = "Google.Chrome"; RegName = "*Chrome*" },
    @{ Name = "Mozilla Firefox"; ID = "Mozilla.Firefox"; RegName = "*Mozilla Firefox*" },
    @{ Name = "7-Zip"; ID = "7zip.7zip"; RegName = "*7-Zip*" }
)

$InstalledApps = @()
$SkippedApps = @()

# جلب لستة أسماء البرامج المثبتة في الريجستري (64 بت و 32 بت) وللمستخدم الحالي
$RegPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$RegList = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue

foreach ($App in $Apps) {
    # الفحص الذكي: هل اسم البرنامج موجود في سجل النظام (Registry)؟
    $CheckReg = $RegList | Where-Object { $_ -like $App.RegName }
    
    if ($CheckReg) {
        Write-Host "[INFO] $($App.Name) is already installed. Skipping..." -ForegroundColor Gray
        $SkippedApps += $App.Name
    } else {
        Write-Host "[..] $($App.Name) NOT found. Installing silently..." -ForegroundColor Cyan
        # تشغيل التثبيت مع إخفاء المخرجات المزعجة لمنع الأخطاء
        $null = winget install --id $($App.ID) --silent --accept-source-agreements --accept-package-agreements --scope user -ErrorAction SilentlyContinue
        $InstalledApps += $App.Name
    }
}
Write-Host "[SUCCESS] All applications checked and processed!" -ForegroundColor Green

# 5. صيد مفتاح تنشيط الويندوز الأصلي من المذربورد
Write-Host "`n[..] Extracting Windows Product Key..." -ForegroundColor Yellow
$WinKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
if ($WinKey) {
    $KeyReport = "$WinKey"
    Write-Host "[SUCCESS] Found Original Windows Key: $KeyReport" -ForegroundColor Cyan
} else {
    $KeyReport = "No digital key found in BIOS (Digital License used)."
    Write-Host "[INFO] $KeyReport" -ForegroundColor Gray
}

# 6. لوحة معلومات الشبكة المتقدمة الفعّالة
Write-Host "`n[..] Checking Network Status..." -ForegroundColor Yellow

# صيد الـ IP الحقيقي المربوط بالإنترنت مباشرة وتخطي الـ APIPA 169.254
$LocalIP = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 -ErrorAction SilentlyContinue | 
            Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
            Where-Object {$_.IPAddress -notlike "169.254*"} | 
            Select-Object -ExpandProperty IPAddress -First 1)

if (-not $LocalIP) {
    $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127*" -and $_.IPAddress -notlike "169.254*"}).IPAddress | Select-Object -First 1
}
if (-not $LocalIP) { $LocalIP = "No Valid IPv4" }

Write-Host "-> Your Local IP: $LocalIP" -ForegroundColor White

if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    $NetReport = "⚡ Connected"
    Write-Host "[SUCCESS] Internet Status: $NetReport" -ForegroundColor Green
} else {
    $NetReport = "❌ Disconnected"
    Write-Host "[ERROR] Internet Status: $NetReport" -ForegroundColor Red
}

# 7. تقرير سريع للمعالج والذاكرة
Write-Host "`n[..] Gathering System Resources..." -ForegroundColor Yellow
$CPU = (Get-WmiObject Win32_Processor).Name
$RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "-> CPU: $CPU" -ForegroundColor White
Write-Host "-> Total RAM: $RAM GB" -ForegroundColor White

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "          [+] PHASE 6 (STABLE) - COMPLETED        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 🌐 8. صياغة التقرير وإرساله إلى تيليجرام
Write-Host "`n[..] Sending Telegram Notification..." -ForegroundColor Yellow

$NewInstalled = if($InstalledApps) { $InstalledApps -join ", " } else { "None (All up to date)" }
$AlreadyThere = if($SkippedApps) { $SkippedApps -join ", " } else { "None" }

$Message = @"
🖥️ *IT AutoHealer - Ultimate Smart Report* 🖥️
============================
👤 *User Name:* $env:USERNAME
🌐 *Local IP:* $LocalIP
📡 *Internet:* $NetReport
💾 *Storage Health:* $HddReport
🧹 *Update Cache Cleared:* $SavedMB MB
📥 *Newly Installed:* $NewInstalled
📦 *Already Installed:* $AlreadyThere
🔑 *Windows Key:* $KeyReport
🧠 *Processor:* $CPU
📟 *Memory RAM:* $RAM GB
============================
✅ *Status:* Diagnostic Finished with 0 Errors!
"@

$URL = "https://api.telegram.org/bot$BotToken/sendMessage"
$Body = @{ chat_id = $ChatID; text = $Message; parse_mode = "Markdown" }
$Response = Invoke-RestMethod -Uri $URL -Method Post -Body $Body -ErrorAction SilentlyContinue

if ($Response.ok) {
    Write-Host "[SUCCESS] Telegram Notification Sent Successfully!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to send Telegram notification." -ForegroundColor Red
}
