param($Beep=$true)

if ($Beep) {
    [console]::beep(2000,500)
    [console]::beep(1500,500)
    [console]::beep(1000,500)
    [console]::beep(500,500)
}

Start-Sleep -s (60*5)

Stop-Computer -Force