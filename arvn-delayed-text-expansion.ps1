$Filepath = "C:\users\me\file.md"
$OriginalText = Get-Content $Filepath
# $OriginalText = "I wo write th on t tablet
# I wo write th on t tablet
# I wo write th on t tablet"


$Rules = @(
    (" wo ", " would "),
    (" t ", " the "),
    (" th ", " this ")
    )

$NewText = $OriginalText
foreach ($Rule in $Rules) {
    $NewText = $NewText.Replace($Rule[0], $Rule[1])
}

#Write-Host $NewText
$NewText | Set-Content $Filepath