$SGName = Read-Host "Enter SG name"
$Users = @()

# Get list of user IDs from the specified group
$Users = az ad group member list --group $SGName --query "[].id" -o tsv

foreach ($User in $Users) {
    try {
        # Remove the user from the group
        az ad group member remove --group $SGName --member $User
        Write-Host "Removed Member: $(az ad user show --id $User --query DisplayName)"
    } catch {
        Write-Host "Unable to remove $User from $SGName"
    }
}
