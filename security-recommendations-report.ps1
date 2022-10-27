param (
    #[Parameter(Mandatory=$true)]
    $CsvFile = "C:\Users\WittAllen\Downloads\DecodeHealth-AzureSecurityCenterRecommendations_2022-10-27T16_56_18Z.csv",

    $ExportedFile = "C:\Users\WittAllen\Downloads\DecodeHealth-script-export-10-27-22.csv"
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
	$Record = $Record | Select-Object "Business Impact","Recommendation","Resource Group","Resource Name","Resource Type","Benefits","Healthy"
    Write-Output "$Record"

	if ($Record."Healthy" -eq "Healthy") {
		$Record."Healthy" = "X"
	} else {
		$Record."Healthy" = " "
	}
}

$FilteredResults | Export-Csv -Path $ExportedFile -Force