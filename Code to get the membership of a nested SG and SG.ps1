# Function to recursively retrieve members of a group
Function Get-GroupTree {
    param(
        [string]$GroupName,
        [int]$IndentLevel = 0
    )

    # Retrieve members of the group
    $Members = Get-ADGroupMember -Identity $GroupName

    foreach ($Member in $Members) {
        # Indentation for tree structure
        $Indent = " " * ($IndentLevel * 4)

        if ($Member.objectClass -eq 'group') {
            # Output the nested group name
            Write-Host "${Indent}Group: $($Member.Name)" -ForegroundColor Cyan

            # Recursively get members of the nested group
            Get-GroupTree -GroupName $Member.DistinguishedName -IndentLevel ($IndentLevel + 1)
        } elseif ($Member.objectClass -eq 'user') {
            # Output user details
            $UserDetails = Get-ADUser -Identity $Member.DistinguishedName -Properties DisplayName, UserPrincipalName
            Write-Host "${Indent}User: $($UserDetails.DisplayName) ($($UserDetails.UserPrincipalName))" -ForegroundColor Green
        } else {
            # Handle other object types
            Write-Host "${Indent}Other: $($Member.Name) ($($Member.objectClass))" -ForegroundColor Yellow
        }
    }
}

# Retrieve groups that match the filter
$RootGroups = Get-ADGroup -Filter {Name -like "SG_EDH_PRD_SQL_Analytics_r"} -Properties * | Select-Object -ExpandProperty Name

# Iterate over each group and display its tree structure
foreach ($GroupName in $RootGroups) {
    Write-Host "Group Membership Tree for '$GroupName':" -ForegroundColor Magenta
    Get-GroupTree -GroupName $GroupName
    Write-Host ""
}