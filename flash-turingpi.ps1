param (
    [Parameter(Mandatory=$true)]
    [String]
    $Password,

    $Username = "witt",

    [Parameter(Mandatory = $true)]
    [String]
    $Hostname,

    $Timezone = "America/Chicago",

    $UserdataFilepath = "E:\user-data"
)


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

Write-Host $Userdata | Out-File $UserdataFilepath -Force