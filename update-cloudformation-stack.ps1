param (
    $BucketName = "witt-test-cf-templates",
    $StackName = "witt-test-carsaver-prod-vpc",
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

# Update CloudFormation stack that has already successfully deployed once
Update-CFNStack -StackName "witt-test-carsaver-prod-vpc" -TemplateURL $S3ObjectURL -Region $DefaultRegion