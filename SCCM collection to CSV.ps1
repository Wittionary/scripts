# Make export path default to logged in user's documents folder
# Make export filename based off of date and time
# Connect to SCCM server first

# then do this
$members = Get-CMCollectionMember -CollectionName "Windows 8/8.1 and OptiPlex 7020" | Select-Object Name,MACAddress,PrimaryUser,LastLogonUser,LastActiveTime,DeviceOS
$members | Export-Csv -Path "C:\Export.csv" -NoTypeInformation