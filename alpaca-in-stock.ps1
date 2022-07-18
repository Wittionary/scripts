# Medium Watauga
$Url = 'https://appalachiangearcompany.com/collections/mens/products/mens-all-paca-fleece-hoodie?variant=37641607807174'
$Response = Invoke-WebRequest $Url

foreach ($Line in $Response) {
    if ($null -ne ($Line | Where-Object { $_ -match 'Medium / Watauga' })) {
        $Availability = $Line
    }
}

if ($Availability -notmatch "Sold Out") {
    Write-Host "Item is in stock! Sending text message."
    Send-TwilioSMS
} else {
    Write-Host "Item not in stock"
}

function Send-TwilioSMS {
    param (
        $TwilioSendingNumber = ""
    )
    $sid = $env:TWILIO_ACCOUNT_SID
    $token = $env:TWILIO_AUTH_TOKEN
    $number = $env:TWILIO_NUMBER

    # Twilio API endpoint and POST params
    $url = "https://api.twilio.com/2010-04-01/Accounts/$sid/Messages.json"
    $params = @{ To = "+15558675309"; From = $number; Body = "Hello from PowerShell" }

    # Create a credential object for HTTP basic auth
    $p = $token | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($sid, $p)

    # Make API request, selecting JSON properties from response
    Invoke-WebRequest $url -Method Post -Credential $credential -Body $params -UseBasicParsing |
    ConvertFrom-Json | Select-Object sid, body

}