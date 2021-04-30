# Medium Watauga
$Url = 'https://appalachiangearcompany.com/collections/mens/products/mens-all-paca-fleece-hoodie?variant=37641607807174'
$Response = curl $Url

foreach ($Line in $Response) {
    if ($null -ne ($Line | Where-Object { $_ -match 'Medium / Watauga' })) {
        $Availability = $Line
    }
}

if ($Availability -notmatch "Sold Out") {
    Write-Host "Item is in stock!"
}