param (
    [Parameter(Mandatory=$true)]
    [String]
    $Password,

    $Username = "witt",

    [Parameter(Mandatory = $true)]
    [String]
    $Hostname,

    $Timezone = "America/Chicago",

    $UserdataFilepath = "E:\user-data",
    $RPiImagerInstallPath = "C:\Program Files (x86)\Raspberry Pi Imager",
    $ImagePath = "D:\Witt\Downloads\hypriotos-rpi-v1.12.3.img\hypriotos-rpi-v1.12.3.img",
    $DestinationDrive = "\\.\PhysicalDrive3"
)
$WorkingDir = (Get-Location).Path

function Setup-Userdata {
  $TempFilename = "$WorkingDir\temp-user-data"

  $Userdata = "#cloud-config
# vim: syntax=yaml
#

# Set your hostname here, the manage_etc_hosts will update the hosts file entries as well
hostname: $Hostname
manage_etc_hosts: true

# You could modify this for your own user information
users:
  - name: $Username
    gecos: `"Hypriot Pirate`"
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    groups: users,docker,video,input
    plain_text_passwd: $Password
    lock_passwd: false
    ssh_pwauth: true
    chpasswd: { expire: false }

# # Set the locale of the system
# locale: `"en_US.UTF-8`"

# # Set the timezone
# # Value of 'timezone' must exist in /usr/share/zoneinfo
# timezone: $Timezone

# # Update apt packages on first boot
# package_update: true
# package_upgrade: true
# package_reboot_if_required: true
package_upgrade: false

# # Install any additional apt packages you need here
# packages:
#  - ntp

# # WiFi connect to HotSpot
# # - use `wpa_passphrase SSID PASSWORD` to encrypt the psk
# write_files:
#   - content: |
#       allow-hotplug wlan0
#       iface wlan0 inet dhcp
#       wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
#       iface default inet dhcp
#     path: /etc/network/interfaces.d/wlan0
#   - content: |
#       country=de
#       ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
#       update_config=1
#       network={
#       ssid=`"YOUR_WIFI_SSID`"
#       psk=`"YOUR_WIFI_PASSWORD`"
#       proto=RSN
#       key_mgmt=WPA-PSK
#       pairwise=CCMP
#       auth_alg=OPEN
#       }
#     path: /etc/wpa_supplicant/wpa_supplicant.conf

# These commands will be ran once on first boot only
runcmd:
  # Pickup the hostname changes
  - 'systemctl restart avahi-daemon'

#  # Activate WiFi interface
#  - 'ifup wlan0'"

  Set-Clipboard $Userdata
  Write-Host "Clipboard has been set to userdata." -ForegroundColor Blue
  $Userdata | Out-File $TempFilename -Force
  #$Userdata | Out-File $UserdataFilepath -Force
  Move-Item $TempFilename $UserdataFilepath -Force

  # Test if data was transferred properly
  $Success = $false
  $Success = Get-ChildItem $UserdataFilepath | Select-String $Hostname
  if ($Success) {
    Write-Host "Userdata written successfully!" -ForegroundColor Green
  } else {
    Write-Host "Hostname `"$Hostname`" not found in userdata.`nManually verify the user-data file is valid before proceeding." -ForegroundColor Red
    Start-Sleep -Seconds 2
    Write-Host "Hit " -NoNewline
    Write-Host "[Enter] " -ForegroundColor Blue -NoNewline
    $null = Read-Host "when the file is in place"
    $null = Read-Host "Are you sure?"
  }
}

function Prepare-Device {
  # You should get a notification that a USB device is being setup. It should start with "BCM"
  Write-Host "Waiting until device is ready..."
  $Device = $null
  while ($null -eq $Device) {
    $Device = Get-PnpDevice -FriendlyName "BCM*" -PresentOnly -ErrorAction SilentlyContinue
    if ($Device) {
      Write-Host "Device found!" -ForegroundColor Green
    }
    else {
      Start-Sleep -Seconds 5
      Write-Host "Waiting until device is ready..." -ForegroundColor Blue
    }
  }
  # Once that's done setting up, run rpiboot from elevated prompt
  Write-Host "Waiting " -ForegroundColor Yellow -NoNewline
  Write-Host "for rpiboot process to complete..."
  & "D:\Program Files (x86)\Raspberry Pi\rpiboot.exe"
  # $rpibootProcess = Get-Process -Name "rpiboot" -ErrorAction SilentlyContinue
  # Wait-Process -Id $rpibootProcess.Id -ErrorAction SilentlyContinue
}

function ManualSteps-Preamble {
  [console]::beep(640, 200)
  [console]::beep(840, 200)
  [console]::beep(940, 200)

  Write-Host "Seat " -ForegroundColor Yellow -NoNewline
  Write-Host "compute module into TPi node # 1"
  Start-Sleep -Seconds 2
  Write-Host "Plug " -ForegroundColor Yellow -NoNewline
  Write-Host "power into TPi"
  Start-Sleep -Seconds 2
}

function ManualSteps-Postamble {
  Write-Host "Remove " -ForegroundColor Yellow -NoNewline
  Write-Host "TPi power cable"
  Start-Sleep -Seconds 2
  Write-Host "Eject " -ForegroundColor Yellow -NoNewline
  Write-Host "the compute module manually"
  Start-Sleep -Seconds 2
  Write-Host "Re-run script if you have more modules to flash ⚡"

  [console]::beep(940, 200)
  [console]::beep(840, 200)
  [console]::beep(640, 200)
}

function Image-Device {
  Write-Host "Writing " -ForegroundColor Yellow -NoNewline
  Write-Host "image to USB drive..."
  
  Set-Location $RPiImagerInstallPath
  & ".\rpi-imager-cli.cmd" --cli $ImagePath $DestinationDrive
  Set-Location $WorkingDir
}

function Eject-UsbDrive {
  # Eject USB drive
  $DriveEject = New-Object -comObject Shell.Application
  $HypriotDrive = Get-CimInstance win32_volume | Where-Object { $_.Label -eq "HypriotOS" }
  $DriveEject.Namespace(17).ParseName($HypriotDrive.Name.Substring(0, 2)).InvokeVerb("Eject")
  Write-Host "Drive ejected" -ForegroundColor Blue
}

# ------------- Where it runs
# Download required programs

ManualSteps-Preamble
Prepare-Device
Image-Device
Start-Sleep -Seconds 3

# After write is complete, open file explorer to the USB device that's mounted named HypriotOS and customize user-data file
Setup-Userdata

Eject-UsbDrive
ManualSteps-Postamble