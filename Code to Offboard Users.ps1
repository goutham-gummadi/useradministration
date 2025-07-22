Connect-ExchangeOnline 
Connect-MgGraph 
Get-Variable | Where-Object { $_.Options -notmatch "ReadOnly|Constant" } | Remove-Variable -Force -ErrorAction SilentlyContinue
$SharedMailboxPath = "OU=Term: SharedMailboxes,OU=Terminated Users-Retain,DC=corp,DC=edhc,DC=com"
$NoSharedMailboxPath = "OU=Offboarded Users (No Sync),DC=corp,DC=edhc,DC=com"
do
{
    # Prompt for the user to offboard
    $UPN=""
    $OffboardedUser = Read-Host "Enter the SamAccountName of the user you want to offboard"

    # Finding if the user exists in Active Directory
    $UserInfo = Get-ADUser -Identity $OffboardedUser -Properties *
    $UPN = $UserInfo.UserPrincipalName
    # Check if the user was found in AD
    if ($UserInfo) {
        $LastWorkingDay = Read-Host "Enter Last Working day MM-DD-YYYY"
        $JIRANumber = Read-Host "Enter JIRA Ticket Number (HR-*****)"
        $NeedSharedMailbox = Read-Host "Need Shared Mailbox? (Y/N)"
        $UserSAM = $UserInfo.SamAccountName
        Write-Host "User SAM: $UserSAM"

        if ($NeedSharedMailbox -eq "Y") {
            $Trustee = Read-Host "Enter the SamAccountName of the person who needs Shared Mailbox access"
        }

        $Title = $UserInfo.Title
        $Description ="OB | $Title | $LastWorkingDay | $JIRANumber"

        # Process group memberships
        $GroupMembership = Get-ADUser -Identity $UserSAM -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        foreach ($Group in $GroupMembership) {
            $GroupName = (Get-ADGroup -Identity $Group).Name
            Write-Host "User has access to Group: $GroupName" -ForegroundColor Cyan
            if ($GroupName -ne "Domain Users") {
                Remove-ADGroupMember -Identity $GroupName -Members $UserSAM -Confirm:$false
                Write-Host "Removed $GroupName from user $OffboardedUser" -ForegroundColor DarkCyan
            } else {
                Write-Host "Not removing 'Domain Users' group"
            }
        }

        # Add user to Terminated Users group
        $TerminatedGroup = Get-ADGroup -Identity "TerminatedUsers"
        try
        {
        Add-ADGroupMember -Identity $TerminatedGroup.SamAccountName -Members $UserSAM -Confirm:$false -ErrorAction Stop
        Write-Host "Added $OffboardedUser to TerminatedUsers Group"
        }
        Catch
        {
        Write-Host "Unable to add $OffboardedUser to TerminatedUsers Group"
        }
        # Update 'info' attribute with Offboarding date
        $UpdatedInfo = $UserInfo.info + "`n || Offboarding Date - $LastWorkingDay | Offboarding TIcket Number- $JIRANumber ||"
        Set-ADUser -Identity $UserSAM -Description $Description -Replace @{info = $UpdatedInfo} -Clear Manager -Enabled $false

        # Set Primary Group ID (must be an integer, not a string)
        Set-ADUser -Identity $UserSAM -Replace @{primaryGroupID = 1716}
        try
        {
        # Remove user from 'Domain Users' group
        Remove-ADGroupMember -Identity "Domain Users" -Members $UserSAM -Confirm:$false -ErrorAction Stop
        Write-Host "Removed Domain Users group from $OffboardedUser"
        }
        Catch
        {
        Write-Host "Unable to remove DomainUsers group from $OffboardedUser"
        }
        # Converting to Shared Mailbox if needed
        if ($NeedSharedMailbox -eq "Y") {
            $TrusteeInfo= Get-ADUser -Identity $Trustee -Properties *
            if ($TrusteeInfo) {
                Set-Mailbox -Identity $UserInfo.UserPrincipalName -Type Shared -ErrorAction Stop
                Add-RecipientPermission -Identity $UserInfo.UserPrincipalName -Trustee $TrusteeInfo.UserPrincipalName -AccessRights SendAs -ErrorAction Stop
                Move-ADObject -Identity $UserInfo.DistinguishedName -TargetPath $SharedMailboxPath -ErrorAction Stop
                Write-Host "Converted $OffboardedUser account into Shared Mailbox"
            } else {
                Write-Host "Trustee Account not found"
            }
        } else {
            Write-Host "User does not need Shared Mailbox"
        }

        # Remove Licenses and Azure groups
        
        $UserAZInfo = Get-MgUser -Filter "Startswith(UserPrincipalName,'$UPN')"
        $LicenceInfo = Get-MgUserLicenseDetail -UserId $UserAZInfo.Id
        $LicenceInfo | ForEach-Object {
            Set-MgUserLicense -UserId $UserAZInfo.Id -AddLicenses @() -RemoveLicenses @($_.SkuId) | Out-Null -ErrorAction Stop
            Write-Host "Removed $($_.SkuPartNumber) license from $OffboardedUser"
        }
        # Get the groups the user is a member of
        $UserAZGroupInfo = Get-MgUserMemberOf -UserId $UserAZInfo.Id
    
        # Loop through each group the user is a member of and get full details
        $UserAZGroupInfo | ForEach-Object {
        try {
            $groupDetails = Get-MgGroup -GroupId $_.Id            
            Write-Host "Group Name: $($groupDetails.DisplayName) | Group ID: $($groupDetails.Id)" -ForegroundColor Cyan
            if ($groupDetails.GroupType -eq "DistributionGroup") {
            Remove-DistributionGroupMember -Identity $groupDetails.Id -Member $UserAZInfo.Id
            Write-Host "Removed user from Distribution Group: $($groupDetails.DisplayName)" -ForegroundColor Yellow
        }
           
        } catch {
            Write-Host "Failed to retrieve details for group ID: $_.Id" -ForegroundColor Red
        }
    }
        Move-ADObject -Identity $UserInfo.DistinguishedName -TargetPath $NoSharedMailboxPath
    } else {
        Write-Host "User not found in Active Directory."
    }

    $Continue = Read-Host "Do you want to offboard another user?(Y/N):"
} while ($Continue -eq "Y")

Write-Host "Script executed successfully" -ForegroundColor Red






























#----------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------
#$Device = Get-MgUserRegisteredDevice -UserId $User.Id 
#Update-MgDevice -DeviceId $Device.Id -AccountEnabled:$false
#Revoke-MgUserSignInSession -UserId $User.Id