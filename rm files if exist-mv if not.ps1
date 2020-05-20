# Use for incomplete mass-move or mass-copy file operations
param (
    $DirectoryFilesExist = "D:\Documents\TpyoedFolderName\",
    $DirectoryFilesShouldExist = "D:\Documents\FolderName\"
)

$FilesRemoved = 0
$FilesMoved = 0
$Files = Get-ChildItem $DirectoryFilesExist*

$FilesRemovedList = @()
$FilesMovedList = @()

foreach ($File in $Files) {
    if (test-path "$DirectoryFilesShouldExist$($File.name)") {
        Remove-Item $File
        $FilesRemovedList += $File
        $FilesRemoved++
    } else {
        Move-Item $File -Destination $DirectoryFilesShouldExist
        $FilesMovedList += $File
        $FilesMoved++
    }
}

Write-host "$FilesRemoved files removed`n$FilesMoved files moved"