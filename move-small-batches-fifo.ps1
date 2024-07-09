# move one file at a time from prod-queue to prod-queue-pg
param (
    [ValidateScript({Test-Path $_})]
    [string]
    $Source = "E:\production-queue\",

    [ValidateScript({Test-Path $_})]
    [string]
    $Destination = "E:\production-queue-pg\",

    [Boolean]
    $TestRun = $true,

    [Int32]
    $BatchSize = 50,

    [Int32]
    $Wait = 2.2 # in seconds
)
Write-Host "!!! Run this locally on the server that holds the files. !!!" -ForegroundColor Yellow


function make-batch {
    param (
        [Parameter(Mandatory)]
        $RemainingFiles,

        [Int32]
        $BatchSize = $BatchSize
    )
    # get a few oldest files
    Write-Host "`tGetting the $BatchSize oldest..."
    $Batch = $RemainingFiles | Select-Object -First $BatchSize

    return $Batch
}

function move-batch {
    param (
        [Parameter(Mandatory)]
        $Batch, 

        [ValidateScript({Test-Path $_})]
        [string]
        $Source = $Source,
    
        [ValidateScript({Test-Path $_})]
        [string]
        $Destination = $Destination  
    )

    # move from source to destination
    Write-Host "`tMoving batch..."
    Move-Item -Path $Batch.FullName -Destination $Destination -Verbose
}

# get all files
Write-Host "Getting all files..."
$AllFiles = Get-ChildItem $Source | Sort-Object LastWriteTime
Write-Host "File count: $($AllFiles.Count)"

if ($TestRun) {
    $Batch = make-batch -RemainingFiles $AllFiles -BatchSize $BatchSize
    move-batch -Source $Source -Destination $Destination -Batch $Batch
} else {
    $Prompt = Read-Host -Prompt "You're about to run a recurring batch move that will run until completion.
    `nAre you sure you want to continue? (y/N)"
    if (($Prompt.ToLower().Substring(0,1) -ne "y") -and ($Prompt.ToLower().Substring(0,1) -ne "")) {
        Write-Host "Exiting"
        exit 0
    } 

    $Count = $AllFiles.Count
    $OldCount = $Count
    $RemainingFiles = $AllFiles
    # loop until $Source is empty
    while ($Count -gt 0) {
        # progress bar
        $progressOptions = @{
            Activity         = "Moving files..."
            #SecondsRemaining = (($count * $delay) - ($i * $delay))
            PercentComplete  = ((($OldCount - $Count) / $OldCount ) * 100)
        }
        Write-Progress @progressOptions 
        
        Write-Host "`tFiles remaining: $Count"
        #Write-Host "`tDelta from last loop: $($OldCount - $Count)"
        
        # get a new batch
        $Batch = make-batch -RemainingFiles $RemainingFiles -BatchSize $BatchSize

        # move a batch
        move-batch -Source $Source -Destination $Destination -Batch $Batch

        # offset the next batch
        $RemainingFiles = $RemainingFiles[$BatchSize..$($AllFiles.Count - 1)]
        $Count = $RemainingFiles.Count

        # wait
        Write-Host "`tSleeping..."
        Start-Sleep -Seconds $Wait
    }
    Write-Host "Script complete!" -ForegroundColor Green
}