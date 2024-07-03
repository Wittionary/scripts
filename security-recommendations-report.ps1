# DESCRIPTION:
# Transform a CSV export of Azure's "Microsoft Defender for Cloud" recommendations
# into something more comprehensible from a user perspective

param (
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    $CsvFile,

	[Parameter(Position=1)]
    $ExportedFile = "C:\Users\WittAllen\Downloads\DecodeHealth-script-export-$(Get-Date -Format yyyy-MM-dd).csv"
)

$Csv = Import-Csv -Path $CsvFile
$SpecificColumns = $Csv | Select-Object severity,recommendationDisplayName,resourceGroup,resourceName,resourceType,controls,state
$FilteredResults = $SpecificColumns | Where-Object {$_.state -ne "NotApplicable"}

foreach ($Record in $FilteredResults) {
	# Change column headers
	$Record | Add-Member -Name "Business Impact" -Value $Record.severity -MemberType NoteProperty
	$Record | Add-Member -Name "Recommendation" -Value $Record.recommendationDisplayName -MemberType NoteProperty
	$Record | Add-Member -Name "Resource Group" -Value $Record.resourceGroup -MemberType NoteProperty
	$Record | Add-Member -Name "Resource Name" -Value $Record.resourceName -MemberType NoteProperty
	$Record | Add-Member -Name "Resource Type" -Value $Record.resourceType -MemberType NoteProperty
	$Record | Add-Member -Name "Benefits" -Value $Record.controls -MemberType NoteProperty
	$Record | Add-Member -Name "Healthy" -Value $Record.state -MemberType NoteProperty
    
	if ($Record."Healthy" -eq "Healthy") {
		$Record."Healthy" = "X"
	} else {
		$Record."Healthy" = " "
	}
}
$FilteredResults = $FilteredResults | Select-Object "Business Impact","Recommendation","Resource Group","Resource Name","Resource Type","Benefits","Healthy"

Write-Host "$($PSStyle.Foreground.Yellow)First 3 records of report:$($PSStyle.Reset)"
$FilteredResults | Select-Object -First 3

$UserResponse = Read-Host -Prompt "Continue with export? Y/n"
if (($UserResponse -eq "") -or ($UserResponse -match "y")) {
	$FilteredResults | Export-Csv -Path $ExportedFile -Force
	Write-Host "Report exported to:`n`t$ExportedFile"
} else {
	Write-Host "Report not exported."
}
