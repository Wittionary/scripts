param (
    $BucketName = "witt-test-cf-templates",
    $StackName = "routing",
    $S3Object = "routing.yml",
    $DefaultRegion = "us-west-1"
)
# Update yaml file
# Save it

# AWS CLI prep-work
$S3ObjectURL = "https://$BucketName.s3.$DefaultRegion.amazonaws.com/$S3Object"
Set-DefaultAWSRegion -Region $DefaultRegion

# Upload to S3
Write-S3Object -BucketName $BucketName -File "$Env:git\pg\pts-witt-scratchpad\carsaver\NT220207a - CarSaver AWS CloudFormation\$S3Object"

# Update (or create) CloudFormation stack
$PauseForDeletion = $false
try {
    $CurrentStack = Get-CFNStack -StackName $StackName -Region $DefaultRegion
    if ($CurrentStack.StackStatus -eq "ROLLBACK_COMPLETE") {
        # stack was created but never successful, just delete it
        Remove-CFNStack -StackName $StackName -Region $DefaultRegion -Force
        $PauseForDeletion = $true
        $CurrentStack = $null
    }
} catch { # ErrorAction isn't supported by AWS pwsh so try-catch is needed
    $CurrentStack = $null
}
if ($null -eq $CurrentStack) {
    # Stack does not yet exist
    # Create it with template
    if ($PauseForDeletion) {
        Start-Sleep -Seconds 5
    }
    New-CFNStack -StackName $StackName -TemplateURL $S3ObjectURL -Region $DefaultRegion -Capability "CAPABILITY_NAMED_IAM"
} else {
    Update-CFNStack -StackName $StackName -TemplateURL $S3ObjectURL -Region $DefaultRegion -Capability "CAPABILITY_NAMED_IAM"
}
