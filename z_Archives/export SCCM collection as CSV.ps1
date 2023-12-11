# Convert an SCCM collection into a CSV

# Connect to SCCM server first
# then do this
$members = Get-CMCollectionMember -CollectionName "Windows 8/8.1 and OptiPlex 7020" | Select-Object Name,MACAddress,PrimaryUser,LastLogonUser,LastActiveTime,DeviceOS
$members | Export-Csv -Path "$env:USERPROFILE\Documents\Export-$(Get-Date -Format yyyy-MM-dd_HHmm).csv" -NoTypeInformation