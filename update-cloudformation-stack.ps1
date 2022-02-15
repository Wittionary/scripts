param (
    $BucketName = "witt-test-cf-templates",
    $StackName = "witt-test-02-15-1311",
    $S3Object = "prod-vpc.yml",
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
$CurrentStack = Get-CFNStack -StackName $StackName -Region $DefaultRegion -ErrorAction SilentlyContinue
if ($null -eq $CurrentStack) {
    # Stack does not yet exist
    # Create it with template
    New-CFNStack -StackName $StackName -TemplateURL $S3ObjectURL -Region $DefaultRegion
} else {
    Update-CFNStack -StackName $StackName -TemplateURL $S3ObjectURL -Region $DefaultRegion
}
