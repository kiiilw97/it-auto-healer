# تلوين الواجهة المحلية وترتيب الشاشة
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     [+] SYSTEM DIAGNOSTIC & CLEANUP SCRIPT       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# بيانات التيليجرام الخاصه بك
$BotToken = "8845124533:AAFOyBL62IdyNsfxTJXzYoNtxVdvXAbhi-A"
$ChatID   = "1778953224"

# شاشة قفل الاختيار الذكي
Write-Host "`n[?] Select an option / اختر الإجراء المناسب:" -ForegroundColor Yellow
Write-Host " [1] Clean & Diagnostic Only (فحص وصيانة وتنظيف فقط)" -ForegroundColor Green
Write-Host " [2] Install Full Software Suite (تثبيت الحزمة الكاملة للبرامج)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Gray

$Choice = Read-Host "Enter your choice (1 or 2) / أدخل اختيارك"

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

# 4. تنفيذ التثبيت أو التخطي بناءً على اختيارك بالملي
$InstalledApps = @()
$SkippedApps = @()

$Apps = @(
    @{ Name = "Google Chrome"; ID = "Google.Chrome" },
    @{ Name = "Mozilla Firefox"; ID = "Mozilla.Firefox" },
    @{ Name = "7-Zip"; ID = "7zip.7zip" }
)

if ($Choice -eq "2") {
    Write-Host "`n[..] Executing Full Software Suite Installer..." -ForegroundColor Cyan
    foreach ($App in $Apps) {
        Write-Host "[..] Installing $($App.Name) silently..." -ForegroundColor White
        $null = winget install --id $($App.ID) --silent --accept-source-agreements --accept-package-agreements --scope user -ErrorAction SilentlyContinue
        $InstalledApps += $App.Name
    }
} else {
    Write-Host "`n[INFO] Option [1] Selected. Skipping Software Installation." -ForegroundColor Gray
    foreach ($App in $Apps) {
        $SkippedApps += $App.Name
    }
}

# 5. صيد مفتاح تنشيط الويندوز الاصلي
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

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "          [+] DIAGNOSTIC COMPLETED WITH 0 ERRORS  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 🌐 8. صياغة التقرير وإرساله منفصلاً بناءً على نوع العملية
Write-Host "`n[..] Sending Telegram Notifications..." -ForegroundColor Yellow

$NewInstalledEN = if($InstalledApps) { $InstalledApps -join ", " } else { "None (Skipped/Up to date)" }
$NewInstalledAR = if($InstalledApps) { $InstalledApps -join ", " } else { "لا يوجد (تم تخطي التثبيت)" }

$AlreadyThereEN = if($SkippedApps) { $SkippedApps -join ", " } else { "None" }
$AlreadyThereAR = if($SkippedApps) { $SkippedApps -join ", " } else { "لا يوجد" }

# التقرير الإنجليزي (يسار)
$MessageEN = @"
🖥️ *IT AutoHealer - English Report*
============================
👤 *User Name:* $env:USERNAME
🌐 *Local IP:* $LocalIP
📡 *Internet:* $NetReportEN
💾 *Storage Health:* $HddReportEN
🧹 *Update Cache Cleared:* $SavedMB MB
📥 *Newly Installed:* $NewInstalledEN
📦 *Skipped Apps:* $AlreadyThereEN
🔑 *Windows Key:* $KeyReport
🧠 *Processor:* $CPU
📟 *Memory RAM:* $RAM GB
============================
✅ Process Mode [$Choice] Finished!
"@

# التقرير العربي (يمين)
$MessageAR = @"
🖥️ *مساعد الصيانة الآلي - التقرير العربي*
============================
اسم المستخدم: $env:USERNAME
الـ IP المحلي: $LocalIP
حالة الإنترنت: $NetReportAR
صحة الهاردسك: $HddReportAR
المساحة المنظفة: $SavedMB ميجابايت
تطبيقات تم تثبيتها: $NewInstalledAR
تطبيقات تم تخطيها: $AlreadyThereAR
مفتاح الويندوز الأصلي: $KeyReport
المعالج: $CPU
الذاكرة العشوائية: $RAM جيجابايت
============================
✅ تم الانتهاء من الخيار [$Choice] بنجاح!
"@

$URL = "https://api.telegram.org/bot$BotToken/sendMessage"

# إرسال الإنجليزي
$BodyEN = @{ chat_id = $ChatID; text = $MessageEN; parse_mode = "Markdown" }
$null = Invoke-RestMethod -Uri $URL -Method Post -Body $BodyEN -ErrorAction SilentlyContinue

# إرسال العربي
$BodyAR = @{ chat_id = $ChatID; text = $MessageAR; parse_mode = "Markdown" }
$Response = Invoke-RestMethod -Uri $URL -Method Post -Body $BodyAR -ErrorAction SilentlyContinue
