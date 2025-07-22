# Get all distribution groups with name and managedBy
$groups = Get-DistributionGroup -Filter * | Select-Object Name, ManagedBy

# Loop through each group
foreach ($group in $groups) {
    foreach ($owner in $group.ManagedBy) {
        if ($owner -eq "") {
            Write-Host "$($group.Name)"
        }
    }
}
