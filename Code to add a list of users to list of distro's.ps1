# List of users to add (can be UPNs or email addresses)
$users = @("")

# List of distribution groups
$distributionLists = @("")

# Loop through each DL and add each user
foreach ($dl in $distributionLists) {
    foreach ($user in $users) {
        try {
            Add-DistributionGroupMember -Identity $dl -Member $user -ErrorAction Stop
            Write-Host "✅ Added $user to $dl"
        } catch {
            Write-Warning "⚠️ Failed to add $user to $dl : $_"
        }
    }
}
