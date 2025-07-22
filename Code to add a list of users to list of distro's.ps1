# List of users to add (can be UPNs or email addresses)
$users = @("elvis.basang@edhc.com")

# List of distribution groups
$distributionLists = @("it@lanterncare.com","info_security@lanterncare.com","drktrc_critialhigh@edhc.com","drktrc_alerts@lanterncare.com","alerts-seim@edhc.com","alerts-crowdstrike@lanterncare.com")

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
