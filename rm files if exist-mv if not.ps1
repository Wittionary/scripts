# Use for incomplete mass-move or mass-copy file operations

$DirectoryFilesExist = "D:\Documents\TpyoedFolderName\"
$DirectoryFilesShouldExist = "D:\Documents\FolderName\"
$FilesRemoved = 0
$FilesMoved = 0
$Files = Get-ChildItem $DirectoryFilesExist*


foreach ($File in $Files) {
    if (test-path "$DirectoryFilesShouldExist$($File.name)") {
        Remove-Item $file
        $FilesRemoved++
    } else {
        Move-Item $file -Destination $DirectoryFilesShouldExist
        $FilesMoved++
    }
}

Write-host "$FilesRemoved files removed`n$FilesMoved files moved"