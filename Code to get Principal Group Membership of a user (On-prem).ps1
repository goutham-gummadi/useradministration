﻿# Define the user's SAM account name or username

$userSAM = Read-Host "Enter user SAM"

# Get the user object with the MemberOf property
$user = Get-ADUser -Identity $userSAM -Properties MemberOf

# Output all groups the user is a member of
$user.MemberOf | ForEach-Object {
    # Get the group details (optional)
    Get-ADGroup -Identity $_ | Select-Object Name
}

& "" -userdata $userSAM

Write-Host "Script Completed" -ForegroundColor Red
