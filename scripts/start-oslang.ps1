# Settings
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'

# Force TLS 1.2 (Required in WinPE for HTTPS APIs)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------------------------------------------------------
# Detect Country Code (Layered Detection)
# -------------------------------------------------------
$countryCode = $null

# 1️⃣ Cloudflare
try {
    $trace = Invoke-WebRequest -Uri "https://www.cloudflare.com/cdn-cgi/trace" -UseBasicParsing -TimeoutSec 10
    $locLine = ($trace.Content -split "`n" | Where-Object { $_ -like "loc=*" })
    if ($locLine) {
        $countryCode = ($locLine -split "=")[1]
        Write-Host "Detected via Cloudflare: $countryCode"
    }
}
catch {}

# 2️⃣ ipinfo.io fallback
if (-not $countryCode) {
    try {
        $geo = Invoke-RestMethod -Uri "https://ipinfo.io/json" -UseBasicParsing -TimeoutSec 10
        $countryCode = $geo.country
        Write-Host "Detected via ipinfo: $countryCode"
    }
    catch {}
}

# 3️⃣ System locale fallback (offline capable)
if (-not $countryCode) {
    try {
        $countryCode = (Get-Culture).Name.Split("-")[1]
        Write-Host "Detected via system locale: $countryCode"
    }
    catch {}
}

# 4️⃣ Final fallback
if (-not $countryCode) {
    $countryCode = "US"
    Write-Host "Falling back to US"
}

# -------------------------------------------------------
# Country Code → Country + Default Language Mapping
# -------------------------------------------------------
$countryMap = @{
    "AU" = @{ Country="Australia";      Code="en-au" }
    "BE" = @{ Country="Belgium";        Code="nl-be" }
    "BR" = @{ Country="Brazil";         Code="pt-br" }
    "CA" = @{ Country="Canada";         Code="en-ca" }
    "CN" = @{ Country="China";          Code="zh-cn" }
    "DK" = @{ Country="Denmark";        Code="da-dk" }
    "FI" = @{ Country="Finland";        Code="fi-fi" }
    "FR" = @{ Country="France";         Code="fr-fr" }
    "DE" = @{ Country="Germany";        Code="de-de" }
    "HU" = @{ Country="Hungary";        Code="hu-hu" }
    "IN" = @{ Country="India";          Code="en-in" }
    "IE" = @{ Country="Ireland";        Code="en-ie" }
    "IL" = @{ Country="Israel";         Code="he-il" }
    "IT" = @{ Country="Italy";          Code="it-it" }
    "JP" = @{ Country="Japan";          Code="ja-jp" }
    "MX" = @{ Country="Mexico";         Code="es-mx" }
    "NL" = @{ Country="Netherlands";    Code="nl-nl" }
    "NZ" = @{ Country="New Zealand";    Code="en-nz" }
    "NO" = @{ country="Norway";         Code="nb-no" }
    "PL" = @{ Country="Poland";         Code="pl-pl" }
    "KR" = @{ Country="South Korea";    Code="ko-kr" }
    "ES" = @{ Country="Spain";          Code="es-es" }
    "SE" = @{ Country="Sweden";         Code="sv-se" }
    "CH" = @{ Country="Switzerland";    Code="de-ch" }
    "TR" = @{ Country="Turkey";         Code="tr-tr" }
    "TW" = @{ Country="Taiwan";         Code="cn-tw" }
    "GB" = @{ Country="United Kingdom"; Code="en-gb" }
    "US" = @{ Country="United States";  Code="en-us" }
    "VN" = @{ Country="Vietnam";        Code="vi-vn" }
}

if ($countryMap.ContainsKey($countryCode)) {
    $DetectedCountry = $countryMap[$countryCode].Country
    $DetectedLangCode = $countryMap[$countryCode].Code
}
else {
    $DetectedCountry = "United States"
    $DetectedLangCode = "en-us"
}

Write-Host "Mapped Country: $DetectedCountry"
Write-Host "Mapped Default Language: $DetectedLangCode"

# -------------------------------------------------------
# GUI Language Selection
# -------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(450,180)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.KeyPreview = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Select the Windows language to install:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($label)

$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(20,50)
$comboBox.Size = New-Object System.Drawing.Size(390,25)
$comboBox.DropDownStyle = "DropDownList"
$form.Controls.Add($comboBox)

$languages = @(
    @{ Country="Australia"; Code="en-au" },
    @{ Country="Belgium"; Code="fr-be" },
    @{ Country="Belgium"; Code="nl-be" },
    @{ Country="Brazil"; Code="pt-br" },
    @{ Country="Canada"; Code="en-ca" },
    @{ Country="Canada"; Code="fr-ca" },
    @{ Country="China"; Code="zh-cn" },
    @{ Country="Denmark"; Code="da-dk" },
    @{ Country="Finland"; Code="fi-fi" },
    @{ Country="France"; Code="fr-fr" },
    @{ Country="Germany"; Code="de-de" },
    @{ Country="Hungary"; Code="hu-hu" },
    @{ Country="India"; Code="en-in" },
    @{ Country="Ireland"; Code="en-ie" },
    @{ Country="Israel"; Code="he-il" },
    @{ Country="Italy"; Code="it-it" },
    @{ Country="Japan"; Code="ja-jp" },
    @{ Country="Mexico"; Code="es-mx" },
    @{ Country="Netherlands"; Code="nl-nl" },
    @{ Country="New Zealand"; Code="en-nz" },
    @{ Country="Norway"; Code="nb-no"},
    @{ Country="Norway"; Code="nn-no"},
    @{ Country="Poland"; Code="pl-pl" },
    @{ Country="South Korea"; Code="ko-kr" },
    @{ Country="Spain"; Code="es-es" },
    @{ Country="Sweden"; Code="sv-se" },
    @{ Country="Switzerland"; Code="de-ch" },
    @{ Country="Switzerland"; Code="fr-ch" },
    @{ Country="Switzerland"; Code="it-ch" },
    @{ Country="Taiwan"; Code="cn-tw"},
    @{ country="Turkey"; Code="tr-tr"},
    @{ Country="United Kingdom"; Code="en-gb" },
    @{ Country="United States"; Code="en-us" },
    @{ Country="Vietnam"; Code="vi-vn" }
)

$languages = $languages | Sort-Object Country, Code

foreach ($lang in $languages) {
    $display = "$($lang.Country) - $($lang.Code)"
    $comboBox.Items.Add($display) | Out-Null

    if ($lang.Country -eq $DetectedCountry -and $lang.Code -eq $DetectedLangCode) {
        $comboBox.SelectedItem = $display
    }
}

# Fallback selection safety
if (-not $comboBox.SelectedItem) {
    $comboBox.SelectedItem = "United States - en-us"
}

# OK / Cancel Buttons
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(150,90)
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

$okButton.Add_Click({
    $form.Tag = ($comboBox.SelectedItem -split " - ")[1]
    $form.Close()
})

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(250,90)
$form.Controls.Add($cancelButton)
$form.CancelButton = $cancelButton

$cancelButton.Add_Click({
    Write-Host "Cancelled."
    $form.Tag = $null
    $form.Close()
})

# Timeout
$remaining = 60
$form.Text = "Select Windows Language ($remaining)"

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

$timer.Add_Tick({
    $remaining--
    $form.Text = "Select Windows Language ($remaining)"
    if ($remaining -le 0) {
        $timer.Stop()
        $form.Tag = ($comboBox.SelectedItem -split " - ")[1]
        $form.Close()
    }
})

$timer.Start()
$form.ShowDialog() | Out-Null

if (-not $form.Tag) { exit 1 }

$OSLanguage = $form.Tag
Write-Host "Final Language Selection: $OSLanguage"

# -------------------------------------------------------
# OSDCloud Configuration
# -------------------------------------------------------
$Global:MyOSDCloud = [ordered]@{
    Restart = $True
    RecoveryPartition = $True
    OEMActivation = $True
    WindowsUpdate = $False
    WindowsUpdateDrivers = $True
    WindowsDefenderUpdate = $True
    SetTimeZone = $False
    ClearDiskConfirm = $True
    ShutdownSetupComplete = $False
    SyncMSUpCatDriverUSB = $True
    CheckSHA1 = $True
}

Start-OSDCloud `
    -OSName $OSName `
    -OSEdition $OSEdition `
    -OSActivation $OSActivation `
    -OSLanguage $OSLanguage