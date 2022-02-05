# Copy results of a query/report from SCCM and format it to readable plaintext
$all = "the contents of your clipboard here"
$split = $all.split("    ") # Four spaces
$range = 1..$($split.count)
$indices = $range | Where-Object -FilterScript {($_ % 10) -eq 1}

$names = @()
foreach ($index in $indices) {
    $names += $split[$index]
}

Write-Host $names