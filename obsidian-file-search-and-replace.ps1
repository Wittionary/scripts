# Remove [[person]] links from daily notes in Obsidian
param (
    $VaultNames = "$($env:git)\obsidian-vaults\notey-notes\",
    $FilenameMatch = "20*-*-*",
    $LookFor = "\[\[\d{4}-\d{2}-\d{2}\]\]\s\|\s\[\[\d{4}-\d{2}-\d{2}\]\]",
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

