# Import the Active Directory module
Import-Module ActiveDirectory

# Define the root OU
$rootOU = "OU=People,DC=corp,DC=edhc,DC=com"
$CurrentDate= Get-Date -Format "MM-dd-yyyy"

# Define the CSV file path
$csvFilePath = "C:\Users\ext.goutham.gummadi\Lantern\Technology - Infrastructure\PhyscialAccessAudit\AD Active Users\UsersList_$CurrentDate.csv"
$csvFilePath1 = "C:\Users\ext.goutham.gummadi\Lantern\Technology - Infrastructure\AD data match with ADP\AD current users list\UsersList_$CurrentDate.csv"

# Retrieve all user accounts from the specified OU and its sub-OUs
$userAccounts = Get-ADUser -Filter * -SearchBase $rootOU -SearchScope Subtree -Property DisplayName, Title, Department, UserPrincipalName, Info, SamAccountName, EmailAddress, Description, Manager, Company

# Prepare an array to hold user data
$userData = @()

# Loop through the user accounts
foreach ($user in $userAccounts) {
    # Retrieve the manager's distinguished name (DN)
    $ManagerDN = $user.Manager

    # Initialize variables for manager's information
    $ManagerDisplayName = ""

    # If the user has a manager, retrieve the manager's display name
    if ($ManagerDN) {
        $ManagerInfo = Get-ADUser -Identity $ManagerDN -Property DisplayName
        $ManagerSAM = $ManagerInfo.SamAccountName
    }

    # Add the user's information and manager's display name to the userData array
    $userData += [PSCustomObject]@{
        DisplayName       = $user.DisplayName
        Title             = $user.Title
        Department        = $user.Department
        UserPrincipalName = $user.UserPrincipalName
        Info              = $user.Info
        SamAccountName    = $user.SamAccountName
        EmailAddress      = $user.EmailAddress
        Description       = $user.Description
        ManagerSAM        = $ManagerSAM
        Company           = $user.Company
    }
}

# Export the user data to a CSV file
$userData | Export-Csv -Path $csvFilePath  -NoTypeInformation -Encoding UTF8
$userData | Export-Csv -Path $csvFilePath1  -NoTypeInformation -Encoding UTF8

Write-Host "User accounts have been exported to $csvFilePath"
