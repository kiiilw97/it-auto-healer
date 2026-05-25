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
    $HddReportEN = "🚨 WARNING: Hard Drive Failure Predicted!"
    $HddReportAR = "🚨 تحذير: يتوقع فشل الهاردسك قريباً!"
    Write-Host "[ERROR] $HddReportEN" -ForegroundColor Red
} else {
    $HddReportEN = "✅ Healthy and Clean"
    $HddReportAR = "✅ سليم ونظيف"
    Write-Host "[SUCCESS] Hard Drive Status: $HddReportEN" -ForegroundColor Green
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

# 4. التثبيت الصامت الذكي بالفحص المباشر للملفات والريجستري
Write-Host "`n[..] Starting Smart Software Installer..." -ForegroundColor Yellow

$Apps = @(
    @{ 
        Name = "Google Chrome"
        ID = "Google.Chrome"
        Paths = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe", "$env:LocalAppData\Google\Chrome\Application\chrome.exe")
        RegName = "*Chrome*"
    },
    @{ 
        Name = "Mozilla Firefox"
        ID = "Mozilla.Firefox"
        Paths = @("$env:ProgramFiles\Mozilla Firefox\firefox.exe", "$env:ProgramFiles(x86)\Mozilla Firefox\firefox.exe")
        RegName = "*Mozilla Firefox*"
    },
    @{ 
        Name = "7-Zip"
        ID = "7zip.7zip"
        Paths = @("$env:ProgramFiles\7-Zip\7z.exe", "$env:ProgramFiles(x86)\7-Zip\7z.exe")
        RegName = "*7-Zip*"
    }
)

$InstalledApps = @()
$SkippedApps = @()

$RegPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$RegList = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue

foreach ($App in $Apps) {
    $AlreadyExists = $false

    foreach ($Path in $App.Paths) {
        if (Test-Path $Path) {
            $AlreadyExists = $true
            break
        }
    }

    if (-not $AlreadyExists) {
        $CheckReg = $RegList | Where-Object { $_ -like $App.RegName }
        if ($CheckReg) { $AlreadyExists = $true }
    }

    if ($AlreadyExists) {
        Write-Host "[INFO] $($App.Name) is already installed. Skipping..." -ForegroundColor Gray
        $SkippedApps += $App.Name
    } else {
        Write-Host "[..] $($App.Name) NOT found. Installing silently..." -ForegroundColor Cyan
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
    $KeyReport = "No digital key found in BIOS / لم يتم العثور على مفتاح في البيوس"
    Write-Host "[INFO] Digital License used." -ForegroundColor Gray
}

# 6. لوحة معلومات الشبكة المتقدمة الفعّالة
Write-Host "`n[..] Checking Network Status..." -ForegroundColor Yellow

$LocalIP = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 -ErrorAction SilentlyContinue | 
            Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
            Where-Object {$_.IPAddress -notlike "169.254*"} | 
            Select-Object -ExpandProperty IPAddress -First 1)

if (-not $LocalIP) {
    $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127*" -and $_.IPAddress -notlike "169.25
