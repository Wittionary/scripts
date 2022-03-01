# Intake a series of CloudFormation templates and spit out a MermaidJS diagram on the order they should be deployed
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Path # Path to folder where templates are
)

# Read the Outputs of each template
# Read the !ImportValues of each template
# Prioritize those with no !ImportValues as lower weight (happens sooner)
# 