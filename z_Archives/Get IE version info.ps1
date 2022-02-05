# Copy and paste a bunch of workstation names, then get their IE version info
$ComputerNamesClipboard = "paste line-separated computer names here"
$ComputerNames = $ComputerNamesClipboard.Split("`n")

# https://gallery.technet.microsoft.com/Get-IEVersionps1-44863ea8
begin { 
  $HKLM = [UInt32] "0x80000002" 
  $IESubKeyName = "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\IEXPLORE.EXE" 
 
  function Get-IEVersion { 
    param( 
      [String] $computerName 
    ) 
    # Create custom object. 
    $outputObject = @{}
    $outputObject.Name = $computerName
    # Step 1: Read App Paths subkey to get path of iexplore.exe. 
    try { 
      $regProv = [WMIClass] "\\$computerName\root\default:StdRegProv" 
    } 
    catch [System.Management.Automation.RuntimeException] { 
      # Update custom object with error message and return it. 
      $outputObject.Error = $_.Exception.InnerException.InnerException.Message 
      return $outputObject 
    } 
    $iePath = ($regProv.GetStringValue($HKLM, $IESubKeyName, "")).sValue 
    if ( -not $iePath ) { 
      # Update custom object with error message and return it. 
      return $outputObject 
    } 
    $outputObject.Path = $iePath 
    # Replace '\' with '\\' when specifying CIM_DataFile key path. 
    $iePath = $iePath -replace '\\', '\\' 
    # Step 2: Get the CIM_DataFile instance of iexplore.exe. 
    try { 
      $dataFile = [WMI] "\\$computerName\root\CIMV2:CIM_DataFile.Name='$iePath'" 
      # Update custom object with IE file version. 
      $outputObject.Version = $dataFile.Version 
    } 
    catch [System.Management.Automation.RuntimeException] { 
      # Update custom object with error message. 
      $outputObject.Error = $_.Exception.InnerException.InnerException.Message 
    } 
    # Return the custom object. 
    return $outputObject
  } 
} 
 
process { 
  foreach ( $ComputerName in $ComputerNames ) { 
    # Get IE version info and return it
    Get-IEVersion $ComputerName #| Select -Property Name,Version,Path,Error
  } 
}