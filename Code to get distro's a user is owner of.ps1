# Get all distribution groups with name and managedBy
$groups = Get-DistributionGroup -Filter * | Select-Object Name, ManagedBy

# Loop through each group
foreach ($group in $groups) {
    foreach ($owner in $group.ManagedBy) {
        if ($owner -eq "743b49cd-01ea-460a-93bb-5f92ab26fa46") {
            Write-Host "$($group.Name)"
        }
    }
}
