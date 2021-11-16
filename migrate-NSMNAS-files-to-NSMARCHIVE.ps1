cd .\ScanFiles\
$BranchDirs = Get-ChildItem -Directory

$Index = 0
foreach ($BranchDir in $BranchDirs) {
    Write-Host "On branch $($Index + 1) of $($BranchDirs.Count)"
    if (test-path "$($BranchDir.Name)\2019\") {
        $ExistingFiles = Get-ChildItem -Path "$($BranchDir.Name)\2019\" -File | Select Name
        Write-Host "BEGIN: $BranchDir has $($ExistingFiles.Count) files"

        
        foreach ($ExistingFile in $ExistingFiles) {
            # Create session if unavailable
            if ($Session.Availability -eq "None") {
                Write-Warning "Creating new PSSession"
                $Session = New-PSSession -ComputerName "server01.domain.local" -Credential $pvlcreds
            }

            # If it already exists on server01, delete from NSMNAS
            try {
                $Time = Get-Date -Format hh:mm.ss
                if (test-path "\\server01.domain.local\E$\apps\ScanFiles\$($BranchDir.Name)\2019\$($ExistingFile.Name)" -ErrorAction Stop) {
                    Write-Host "$($Time) - Removing file $($ExistingFile.Name)"
                    Remove-Item "$($BranchDir.Name)\2019\$($ExistingFile.Name)"
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Warning "$($Time) - Can't yet access .\$($BranchDir.Name)\ to potentially remove file"
            }


            # If it doesn't exist on server01, copy from NSMNAS
            try {
                $Time = Get-Date -Format hh:mm.ss
                if (!(test-path "\\server01.domain.local\E$\apps\ScanFiles\$($BranchDir.Name)\2019\$($ExistingFile.Name)" -ErrorAction Stop)) {
                    Write-Host "$($Time) - Copying file $($ExistingFile.Name)"
                    Copy-Item "$($BranchDir.Name)\2019\$($ExistingFile.Name)" "E:\apps\ScanFiles\$($BranchDir.Name)\2019\$($ExistingFile.Name)" -force -ToSession $Session
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Warning "$($Time) - Can't yet access .\$($BranchDir.Name)\ to potentially copy file"
            }
            
        }

        Write-Host "END: $BranchDir now has $($ExistingFiles.Count) files"
    }
    $Index++
}
$Session | Disconnect-PSSession