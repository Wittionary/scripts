# Remove [[person]] links from daily notes in Obsidian
param (
    $VaultNames = "$($env:git)\obsidian-vaults\notey-notes\",
    $FilenameMatch = "20*-*-*",
    $LookFor = "Previous\s\|\sNext-{3,}",
    $ReplaceWith = "",
    $WhatIf = $true
)

<#
Daily Nav
Previous\s\|\sNext\s-{3,}\|-{3,}\s\[\[\d{4}-\d{2}-\d{2}\]\]\s\|\s\[\[\d{4}-\d{2}-\d{2}\]\]
#>
function Get-DryRunMatches {
    param(
        [Parameter(Mandatory = $true)]
        $Filepath
    )
    Get-Content $Filepath | Where-Object { $_ -match $LookFor }
}

# Return the file size different indicate to user if something might be wrong (i.e. they have a bad search/replace pattern)
function Get-FileSizeDifference {
    param(
        [Parameter(Mandatory = $true)]
        $OriginalFile,
        [Parameter(Mandatory = $true)]
        $ReplacementFile
    )
    $OriginalFileSize = Format-FileSize((Get-Item $OriginalFile).length)
    $ReplacementFileSize = Format-FileSize((Get-Item $ReplacementFile).length)
    
    Write-Warning "FILE SIZE DIFFERENCE:`n`tOriginal - $OriginalFileSize`n`tReplacement - $ReplacementFileSize`n`tDifference - $($OriginalFileSize - $ReplacementFileSize)"
}
# Ripped off the internet: https://www.spguides.com/check-file-size-using-powershell/
Function Format-FileSize {
    Param ([int]$size)
    If ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
    Else {""}
}

$FileCandidates = Get-ChildItem -Path "$VaultNames$FilenameMatch" -Recurse
Write-Host "$($FileCandidates.Count) file candidates"


#$FilesChangedCount = 0
$TotalDryRunMatches = 0
foreach ($FileCandidate in $FileCandidates) {
    if ($WhatIf) {
        # Dry run to see what will be changed
        $DryRunMatches = Get-DryRunMatches -Filepath $FileCandidate.FullName
        $TotalDryRunMatches += $DryRunMatches.Count

        if ($($DryRunMatches.Count) -gt 0) {
            Write-Host "DRY RUN: $($DryRunMatches.Count) matches in $($FileCandidate.Name)"
            Write-Host "DRY RUN:`n`tREPLACE`n$DryRunMatches`n`tWITH`n$ReplaceWith"
        }
    } else {
        (Get-DryRunMatches -Filepath $FileCandidate.FullName) -replace $LookFor, $ReplaceWith | Set-Content $FileCandidate.FullName -Verbose
        #Write-Host "CHANGED: $($FileCandidate.Name)"
        #$FilesChangedCount++
    }
}

if ($WhatIf) {
    Write-Host "$TotalDryRunMatches lines to be changed"
}

