Write-Host "STARTING..." -ForegroundColor Green

$definitionName = "e56962a6-4747-49cd-b67b-bf8b01975c4c" # Builtin policy definition da MS
$displayName = "Allowed locations"
$assignmentName = "Allowed-locations"
$description = "Processor Security Standard"
$parameterFile = ".\AllowedLocations_CurrentlyUsed.json"

Update-AzConfig -DisplayBreakingChangeWarning $false

Write-Host ". Get the Azure subscription Id"  -ForegroundColor Yellow
$subscription = $($(Get-AzContext).Subscription.Id)

Write-Host ". Register the resource provider if it's not already registered" -ForegroundColor Yellow
Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'

if (-not (Get-Module Az.ResourceGraph -ListAvailable)) {
    Write-Host ". Install the Resource Graph module from PowerShell Gallery" -ForegroundColor Yellow
    Install-Module -Name Az.ResourceGraph -Force -Scope CurrentUser
}

Write-Host ". Run Azure Resource Graph query" -ForegroundColor Yellow
$CurrentlyUsedLocations = (Search-AzGraph -Query 'Resources | summarize count() by location | sort by location asc' -Subscription $subscription).location  | Where-Object { $_ -ne '' }

$listOfAllowedLocations = [PSCustomObject]@{
    listOfAllowedLocations = [PSCustomObject]@{
        value = , $CurrentlyUsedLocations
    }
}
$listOfAllowedLocations | ConvertTo-Json | Out-File $parameterFile -Encoding utf8 -Force

Write-Host ". Set the scope of the assignment"  -ForegroundColor Yellow
$policyAssignmentScope = "/subscriptions/$subscription"

try {
    Write-Host ". Try to get the policy assignment"  -ForegroundColor Yellow
    $assignment = $null
    $assignment = Get-AzPolicyAssignment -Name $assignmentName -Scope $policyAssignmentScope -ErrorAction Stop
}
catch {
    Write-Host ". Policy doen not exist"  -ForegroundColor Yellow
}

if (-not ($assignment)) {    
    
    Write-Host ". Get a reference to the built-in policy definition to assign" -ForegroundColor Yellow
    $definition = Get-AzPolicyDefinition -Name $definitionName
    
    Write-Host ". Create the policy assignment with the built-in definition against your resource group" -ForegroundColor Yellow
    $assignment = New-AzPolicyAssignment -Name $AssignmentName -DisplayName $DisplayName -Scope $PolicyAssignmentScope -PolicyDefinition $definition -PolicyParameter $ParameterFile -Description $description
    
}

if ($assignment -and $assignment.Properties.EnforcementMode -eq "DoNotEnforce") {

    Write-Host ". Enforce the Policy Assignment" -ForegroundColor Yellow
    Set-AzPolicyAssignment -Name $assignment.Name -Scope $policyAssignmentScope -EnforcementMode Default

}

#Clean-up
$policyAssignmentScope = $null
$definition = $null
$assignment = $null
Remove-Item -Path $parameterFile -Force

Write-Host "FINISHED" -ForegroundColor Green