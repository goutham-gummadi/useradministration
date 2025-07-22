$ConnectModules= Read-Host "Do you want to connect to modules"
if($connectModules -ne "N")
    {
        &""
    }
$CurrentDateTime= Get-Date -Format "mm-dd-yyy-hh-mm"
$OnboardingUsersData= $null
#Input CSV file
$ImportFilePath= ""
#Output Log File
$LogFile=""
$ExchangeLogfile= ""
#Importing Input data
$OnboardingUsersData= Import-Csv -Path $ImportFilePath
Add-Content -Path $LogFile -Value "Starting Script $CurrentDateTime"













    Function add-UserToBaseGroups{
        param(
            [String]$SamAccountName,
            [String[]]$BaseGroups,
            [String]$LogFile
        )
        foreach ($Group in $BaseGroups) 
                            {
                            try 
                                {
                                Add-ADGroupMember -Identity $Group -Members $SamAccountName
                                Add-Content -Path $LogFile -Value "Added $($SamAccountName) to base group $Group"
                                }
                            catch 
                                {
                                Write-Host "Unable to add $($SamAccountName) to base group $Group"
                                Add-Content -Path $LogFile -Value "Unable to add $($SamAccountName) to base group $Group : $_"
                                }
                            }
    }












foreach($User in $OnboardingUsersData)
	{
	$GivenName = $User.GivenName
    $Surname = $User.Surname
    $Name = $User.Name
    $DisplayName = $User.DisplayName
    $SamAccountName = $User.SamAccountName
    $UserPrincipalName = $User.UserPrincipalName
    $AccountPassword = $User.AccountPassword
    $Title = $User.Title
    $Department = $User.Department
    $Description = $User.Description
    $EmailAddress = $User.EmailAddress
    $Contractor = $User.Contractor
    $Company = $User.Company
    $Manager = $User.Manager
    $HiringDate = $User.HiringDate
    $Ticket= $User.JIRAAD
	
	#Creating New variable to store oboarding and offboarding data
	
	$Hiredate= "|| Hiring date is: $HiringDate | Jira Ticket- $Ticket ||"

    #Check if the user account already exists
    try
        {
        $UserAccountInfo= Get-ADUser -Identity $SamAccountName -Properties * -ErrorAction Stop
        Write-Host "$($DisplayName)'s account is already made"
                       
        if($UserAccountInfo)
            {
            Add-Content -Path $LogFile -Value "$DisplayName account already exists"
            Write-Host "$DisplayName Account Already exists"
            #If user is a rehire
            
                Move-ADObject -Identity $UserAccountInfo.CanonicalName -TargetPath "" -ErrorAction SilentlyContinue
                Set-aduser -Identity $UserAccountInfo.SamAccountName -Enabled:$true -ErrorAction SilentlyContinue


            #Updating existing user information based on current job
             $ManagerInfo= Get-ADUser -Identity $Manager -Properties * -ErrorAction SilentlyContinue
                if($ManagerInfo)
                    {
                    try{
                        Set-ADUser -Identity $UserAccountInfo.SamAccountName -Description $Description -Title $Title -Department $Department -EmailAddress $EmailAddress -Company $Company -Add @{info=$Hiredate} -Manager $ManagerInfo.SamAccountName -ErrorAction SilentlyContinue
                        }
                    catch{
                        Write-Host "Update existing user with managers information"
                        }
                    }
                else{
                    try{
                        Set-ADUser -Identity $UserAccountInfo.SamAccountName -Description $Description -Title $Title -Department $Department -EmailAddress $EmailAddress -Company $Company -Add @{info=$Hiredate} -ErrorAction SilentlyContinue
                        }
                    catch{
                        Write-Host "Update existing user without managers information"
                        }
                    }

            if($Title -eq "Care Advocate")
                        {
                        try
                            {
                            #Getting RBAC memberships
                            $TemplateInfo = Get-ADUser -Identity catemplate -Properties MemberOf
                            $RelavantGroups = $TemplateInfo.MemberOf | Get-ADGroup | Select-Object Name
                            # Get current user to be added to groups
                            $CAUsers = Get-ADUser -Identity $SamAccountName | Select-Object -ExpandProperty SamAccountName
                            # Add the user to each group that the template is a member of
                            if($RelavantGroups)
                                {
                                foreach ($group in $RelavantGroups) 
                                    {
                                    Add-ADGroupMember -Identity $group.Name -Members $CAUsers
                                    Add-Content -Path $LogFile -Value "Added $SamAccountName to $($group.Name)" 
                                    }
                                 }   
                            else
                                {
                                Write-Host "Template is found but unable to retrive groups"
                                }
                            }

                        catch
                            {
                            Write-Host "catemplate is not found"
                            }
                        }
                    else
                        {
                        $BaseGroups = @("")
                        add-UserToBaseGroups -SamAccountName $UserAccountInfo.SamAccountName -BaseGroups $BaseGroups -LogFile $LogFile
                        }
            }
            }
        catch
            {
            Write-Host "User account does not exists"
           

                $ManagerInfo= Get-ADUser -Identity $Manager -Properties * -ErrorAction SilentlyContinue
                if($ManagerInfo)
                    {

                    #If manager is found making new accounts
                    try
                        {
                        New-ADUser -GivenName $GivenName -Surname $Surname -Name $Name -DisplayName $DisplayName `
                        -SamAccountName $SamAccountName -UserPrincipalName $UserPrincipalName `
                        -AccountPassword (ConvertTo-SecureString $AccountPassword -AsPlainText -Force) -Enabled $true `
                        -Title $Title -Department $Department -Description $Description -EmailAddress $EmailAddress `
                        -Path "" -Manager $ManagerInfo.SamAccountName -Company $Company -ErrorAction Stop
                        Write-Host "$DisplayName account is made with Manager info"
                        Add-Content -Path $LogFile -Value "$DisplayName account is made with manager info"
                        }
                    catch
                        {
                        Add-Content -Path $LogFile -Value "Creating $DisplayName account"
                        Write-Host "Unable to create new account (Manager account is found)"
                        }
                    }
                else
                    {

                    #If Manager is not found making new accounts
                    try
                        {
                        Add-Content -Path $LogFile -Value "Creating $DisplayName account"
                        New-ADUser -GivenName $GivenName -Surname $Surname -Name $Name -DisplayName $DisplayName `
                        -SamAccountName $SamAccountName -UserPrincipalName $UserPrincipalName `
                        -AccountPassword (ConvertTo-SecureString $AccountPassword -AsPlainText -Force) -Enabled $true `
                        -Title $Title -Department $Department -Description $Description -EmailAddress $EmailAddress `
                        -Path "" -Company $Company -ErrorAction Stop
                        Write-Host "$DisplayName account is made without Manager info"
                        Add-Content -Path $LogFile -Value "$DisplayName account is made without manager info"
                        }
                    catch
                        {
                        Add-Content -Path $LogFile -Value "Unable to create new account (Manager account is not found)"
                        Write-Host "Unable to create new account (Manager account is not found)"
                        }
                    }           

            #Checking if the account is created and available in AD or not.

  Start-Sleep -Seconds 5          
                $UserAccountInfoPostCreation= Get-ADUser -Identity $SamAccountName -Properties * -ErrorAction SilentlyContinue
                if($UserAccountInfoPostCreation)
                    {
                    Write-Host "User account is found in AD"
                    try
                        {
                        Set-ADUser -Identity $UserAccountInfoPostCreation.SamAccountName -Replace @{info= $Hiredate} -ErrorAction SilentlyContinue
                        Write-Host "Added current action information to Info" 
                        }
                    catch
                        {
                        Write-Host "Unable to update Hiring date for user $DisplayName"
                        }
                    #Adding primary SMTP address
                    $PrimarySMTP="SMTP:$($UserAccountInfoPostCreation.SamAccountName)@lanterncare.com"
                    $SecondarySMTP= "smtp:$($UserAccountInfoPostCreation.UserPrincipalName)"
                    try {
                        Set-ADUser -Identity $UserAccountInfoPostCreation.SamAccountName -Add @{proxyaddresses=$PrimarySMTP} -ErrorAction Continue
                        Set-ADUser -Identity $UserAccountInfoPostCreation.SamAccountName -Add @{proxyaddresses=$SecondarySMTP} -ErrorAction SilentlyContinue
                        Write-Host "Added Primary and Secondary SMTP addresses to user account"
                    }
                    catch {
                        Write-Host "Unable to add SMTP address"
                    }

                    #Assigning groups to user
                    $UserTitlePostAccountCreation= $UserAccountInfoPostCreation.Title
                    if($UserTitlePostAccountCreation -eq "")
                        {
                        try
                            {
                            #Getting RBAC memberships
                            $TemplateInfo = Get-ADUser -Identity  -Properties MemberOf
                            $RelavantGroups = $TemplateInfo.MemberOf | Get-ADGroup | Select-Object Name
                            # Get current user to be added to groups
                            $CAUsers = Get-ADUser -Identity $SamAccountName | Select-Object -ExpandProperty SamAccountName
                            # Add the user to each group that the template is a member of
                            if($RelavantGroups)
                                {
                                foreach ($group in $RelavantGroups) 
                                    {
                                    Add-ADGroupMember -Identity $group.Name -Members $CAUsers
                                    Write-Host "Added $SamAccountName to $($group.Name)"
                                    Add-Content -Path $LogFile -Value "Added $SamAccountName to $($group.Name)" 
                                    }
                                 }   
                            else
                                {
                                Write-Host "Template is found but unable to retrive groups"
                                }
                            }

                        catch
                            {
                            Write-Host "catemplate is not found"
                            }
                        }
                    else
                        {
                        $BaseGroups = @("")
                        add-UserToBaseGroups -SamAccountName $UserAccountInfoPostCreation.SamAccountName -BaseGroups $BaseGroups -LogFile $LogFile
                        }          

                    }
                else
                    {
                    Write-Host "User account is not created properly please check for user $DisplayName"
                    }
           


    $UserAccountInfo= $null
    $UserAccountInfoPostCreation= $null
    $ManagerInfo= $null
    $TemplateInfo= $null
    $RelavantGroups= $null
    $UserTitlePostAccountCreation=$null
    }
    }


Write-Host "Starting Exchange assignments"
Get-Date
#Start-Sleep -Seconds 1500
#Start-Process -FilePath ""

foreach ($User in $OnboardingUsersData) 
    {
    $SamAccountName = $User.SamAccountName
    $UserPrincipalName= $User.UserPrincipalName
    $Contractor = $User.Contractor
  
    if($SamAccountName)
        {
        # Retrieve the user from Active Directory
        $TargetUser = Get-ADUser -Filter {SamAccountName -eq $SamAccountName}

        if ($null -ne $TargetUser) 
            {
            Write-Host "Found user: $($TargetUser.SamAccountName)"
            Add-Content -Path $LogFile -Value "Found user: $($TargetUser.SamAccountName)"

            # Get the user's email address
            $UserEmailAddress = $TargetUser.UserPrincipalName
            $AzureUserInfo= Get-MgUser -UserId $UserEmailAddress -Property *
            $AzureUserID= $AzureUserInfo.Id
            try{
                Update-MgUser -UserId $AzureUserId -UsageLocation 'US'           
                }
            catch{
                Write-Host "Unable to update Usage Location for user $($AzureUserInfo.displayName)" -ForegroundColor Red
                }
            
            $SKUID= ""
            try{
                Set-MgUserLicense -UserId $AzureUserInfo.Id -AddLicenses @{SKUId=$SKUID} -RemoveLicenses @() 
                }
            catch{
                Write-Host "Unable to assign license to user $($AzureUserInfo.displayName)" -ForegroundColor Red
                }

            Write-Host ""
            Write-Host ""
            # Add the user to each distribution list
            $DistributionList = @("")
            foreach ($dl in $DistributionList) 
                {
                Add-DistributionGroupMember -Identity $dl -Member $UserEmailAddress -ErrorAction SilentlyContinue
                Write-Output "Added $($TargetUser.SamAccountName) to $dl"
                Add-Content -Path $LogFile -Value "Added $($TargetUser.SamAccountName) to $dl"
                }
            Start-Sleep -Seconds 10
            $MailEnabledSecurityGroup = @("")
            foreach ($SG in $MailEnabledSecurityGroup) 
                {
                Add-DistributionGroupMember -Identity $SG -Member $UserEmailAddress -ErrorAction SilentlyContinue
                Add-Content -Path $LogFile -Value "Added $($TargetUser.SamAccountName) to $SG"
                Write-Output "Added $($TargetUser.SamAccountName) to $SG"
                }
            Start-Sleep -Seconds 10
            if ($Contractor -ne "TRUE") {
                try {
                    # Construct the odata.id reference
                    $OdataID = @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($AzureUserInfo.Id)"
                    }

                    # Get the group ID for 'TheBrightSides@lanterncare.com'
                    $Brightside = (Get-MgGroup -Filter "mail eq ''" -Property Id).Id

                    # Add the user to the group
                    New-MgGroupMemberByRef -GroupId $Brightside -BodyParameter $OdataID

                    Write-Host "User $($AzureUserInfo.UserPrincipalName) added to TheBrightSides group."
                }
                catch {
                    Write-Warning "Failed to add user $($AzureUserInfo.UserPrincipalName) to group: $_"
                }
            }

            } 
        else 
            {
            Write-Host "User not found: $SamAccountName"
            Add-Content -Path $LogFile -Value "User not found: $SamAccountName"
            }

        }
    else
        {
        Write-Host "End of CSV file"
        }
    
    }


foreach ($User in $OnboardingUsersData) {
    $SamAccountName = $User.SamAccountName
    $UserPrincipalName= $User.UserPrincipalName
    try {
        $UserAZInfo = Get-MgUser -UserId $UserPrincipalName
        Write-Host "Access given to $($UserAZInfo.DisplayName):" -ForegroundColor Cyan

    }
    catch {
        Write-Host "Unable to find user in EntraID" -ForegroundColor Red
    }
    
# Check if the user exists before proceeding
    if ($UserAZInfo) {
    # Get license details of the user
        try
        {   
        $UserLicenseDetails = Get-MgUserLicenseDetail -UserId $UserAZInfo.Id
        $UserLicenseDetails |ForEach-Object{ Write-Host "License Name: $($_.SkuPartNumber)" -ForegroundColor Cyan}
        }
        Catch
        {
        Write-Host "Unable to retrieve License info" -ForegroundColor Red
        }
        $groupDetailsList = @()
    # Get the groups the user is a member of
    $UserAZGroupInfo = Get-MgUserMemberOf -UserId $UserAZInfo.Id
    
    # Loop through each group the user is a member of and get full details
    $UserAZGroupInfo | ForEach-Object {
        try {
        $groupDetails = Get-MgGroup -GroupId $_.Id
        $groupDetailsList += [PSCustomObject]@{
            "Group Name" = $groupDetails.DisplayName
            "Group ID"   = $groupDetails.Id
            "Group Emailaddress" =$groupDetails.Mail
            "On-Prem SYnc Enabled"= $groupDetails.OnPremisesSyncEnabled
            #"Group Source" = $groupDetails.
        } 
        


    } catch {
        Write-Host "Failed to retrieve details for group ID: $($_.Id)" -ForegroundColor Red
    }
    }
    $groupDetailsList | Format-Table -AutoSize
    Write-Host "---------------------------------------------------------------------------------------------------------------"
        Write-Host "---------------------------------------------------------------------------------------------------------------"

} else {
    Write-Host "User with UPN $UserPrincipalName not found." -ForegroundColor Yellow
}
}
