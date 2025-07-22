# Function to recursively get group memberships and build the tree
function Get-GroupMembership {
    param (
        [string]$GroupSam,
        [int]$Depth = 0
    )

    # Initialize the dictionary for the current group
    $MembershipTree = @{}

    # Stop recursion if depth exceeds limit
    if ($Depth -ge 10) {
        Write-Warning "Max recursion depth reached for $GroupSam"
        return $null
    }

    # Get information about the group's parent memberships
    $GroupInfo = Get-ADGroup -Identity $GroupSam -Properties MemberOf -ErrorAction SilentlyContinue | Select-Object -ExpandProperty MemberOf

    if ($GroupInfo) {
        foreach ($ParentGroup in $GroupInfo) {
            # Recursively build the tree for each parent group
            $MembershipTree[$ParentGroup] = Get-GroupMembership -GroupSam $ParentGroup -Depth ($Depth + 1)
        }
    }

    return $MembershipTree
}
$CurrentDate= Get-Date -Format "MM-dd-yyyy"
# Main script to iterate through all groups and build the tree dictionary
$FinalTreeDict = @{}

# Get all groups in Active Directory
$AllGroupsInAD = Get-ADGroup -Filter * -Properties SamAccountName | Select-Object -ExpandProperty SamAccountName

foreach ($GroupSam in $AllGroupsInAD) {
    # Get the membership tree for each group
    $FinalTreeDict[$GroupSam] = Get-GroupMembership -GroupSam $GroupSam
}

# Output the tree dictionary
$FinalTreeDict | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\Users\ext.goutham.gummadi\Downloads\GroupMembershipTree$CurrentDate.json"
