# DESCRIPTION:
# Used for Riverview merger/acquisition

# SMB share where the apps are located
$AppPath = '\\servername\Share$\Apps'

# AnyConnect
$AnyConnectPath = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"
if (!(Test-Path $AnyConnectPath)) {
    & "$AppPath\AnyConnect\anyconnect-win-3.1.14018-pre-deploy-k9.msi"
}

# Outlook
$OutlookPath = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
if (!(Test-Path $OutlookPath)) {
    & "$AppPath\Microsoft Office 365\setup.exe" /configure "$AppPath\Microsoft Office 365\nsm-o365-x64-baseline.xml"
}

# Teams
$TeamsPath = "C:\Users\(current user)\appdata\local\microsoft\teams\update.exe"
if (!(Test-Path $TeamsPath)) {
    & "$AppPath\Microsoft Teams\Teams_windows_x64.msi"
}

# Adobe
$AdobePath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader*"
if (!(Test-Path $AdobePath)) {
    & "$AppPath\Adobe Acrobat DC 2020.012.20041\AcroRdrDC2001220041_en_US.exe"
}

# ConnectWise
$ConnectWisePath = "C:\Program Files (x86)\ScreenConnect Client*"
if (!(Test-Path $ConnectWisePath)) {
    & "$AppPath\ScreenConnect 20.10.957.7556\ScreenConnect_20.10.957.7556_Release.msi"
}

# Chrome
$ChromePath = "C:\Program Files (x86)\Google\"
if (!(Test-Path $ChromePath)) {
    & "$AppPath\Google, Inc. Chrome 78.0.3904.97\GoogleChromeStandaloneEnterprise64.msi"
}