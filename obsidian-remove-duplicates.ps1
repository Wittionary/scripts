Set-Location "$env:git\obsidian-vaults\notey-notes\tickets"

$Originals = Get-ChildItem | Where-Object {($_.FullName -notmatch " 1.md") -and ($_.FullName -notmatch " 2.md")}
$Duplicates = Get-ChildItem | Where-Object {($_.FullName -match " 1.md") -and ($_.FullName -match " 2.md")}

Write-Host "There are $($Duplicates.Count) duplicates"
$DuplicatesRemoved = 0

foreach ($Duplicate in $Duplicates) {
    foreach ($Original in $Originals) {
        if ($Original.name.split(" ", 2)[0] -eq $Duplicate.name.split(" ", 2)[0]) {
            Write-Host "$Original has dupe of $Duplicate"

            # If the same length, delete the duplicate
            if ($Original.Length -eq $Duplicate.Length) {
                Write-Host "----- Killing duplicate: $Duplicate"
                Remove-Item $Duplicate
                $DuplicatesRemoved++
            } else {
                # Compare the difference in data
                Write-Host "Comparing $($Original.Name) to $($Duplicate.Name)"
                # Line by line analysis
                $OriginalContent = Get-Content $Original
                $DuplicateContent = Get-Content $Duplicate
                $EqualContentLines = 0
                $NotEqualContentLineIndices = @()
                if ($null -ne $OriginalContent) {
                    for ($i = 0; $i -lt $OriginalContent.Count; $i++) {
                        if ($OriginalContent[$i] -eq $DuplicateContent[$i]) {
                            $EqualContentLines++
                        } else {
                            $NotEqualContentLineIndices += "$i"
                        }
                    }
                }
                $PercentageMatch = ($EqualContentLines / $OriginalContent.Count)*100
                Write-Host "----- Lines match: $PercentageMatch%"
                if ($PercentageMatch -eq 100) {
                    Write-Host "----- Killing duplicate: $Duplicate"
                    Remove-Item $Duplicate
                    $DuplicatesRemoved++
                } else {
                    #Write-Host "----- Offending indices: $NotEqualContentLineIndices"
                }
            }
        }
    }
}

Write-Host "$DuplicatesRemoved duplicates removed"
