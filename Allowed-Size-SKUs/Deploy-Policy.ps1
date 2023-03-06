#Requires -Modules Az.Accounts,Az.Resources

Write-Host "STARTING..." -ForegroundColor Green

$definitionName = "cccc23c7-8427-4f53-ad12-b6a63eb452b3" # Builtin policy da MS
$displayName = "Allowed virtual machine size SKUs"
$assignmentName = "Allowed-Size-SKUs"
$description = "Processor Security Standard"
$parameterFile = ".\listOfAllowedSKUs.json" # Todos SKUs menos GPU e HPC

Update-AzConfig -DisplayBreakingChangeWarning $false

Write-Host ". Get the Azure subscription Id"  -ForegroundColor Yellow
$subscription = $($(Get-AzContext).Subscription.Id)

Write-Host ". Register the resource provider if it's not already registered" -ForegroundColor Yellow
Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights'

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
    $assignment = New-AzPolicyAssignment -Name $AssignmentName -DisplayName $DisplayName -Scope $PolicyAssignmentScope -PolicyDefinition $definition -PolicyParameter $ParameterFile  -Description $description

}

if ($assignment -and $assignment.Properties.EnforcementMode -eq "DoNotEnforce") {

    Write-Host ". Enforce the Policy Assignment" -ForegroundColor Yellow
    Set-AzPolicyAssignment -Name $assignment.Name -Scope $policyAssignmentScope -EnforcementMode Default

}

#Clean-up
$policyAssignmentScope = $null
$definition = $null
$assignment = $null

Write-Host "FINISHED" -ForegroundColor Green