# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All"

# Import Excel data (requires ImportExcel module)
$csvfile = ""
$csvdata = Import-Excel -Path $csvfile

foreach ($user in $csvdata) {
    $name = $user.name
    if($name){
    # Query user(s) by display name prefix
    $matchedUsers = Get-MgUser -Filter "startswith(userprincipalname,'$name')" -ConsistencyLevel eventual -CountVariable count -All

    if ($matchedUsers.Count -eq 0) {
        Write-Warning "No user found matching name: $name"
        continue
    }

    foreach ($matchedUser in $matchedUsers) {
        Write-Host "`nUser: $($matchedUser.DisplayName) ($($matchedUser.UserPrincipalName))" -ForegroundColor Cyan
        Set-MgUserLicense -UserId $matchedUsers.Id -AddLicenses @{SKUId=""} -RemoveLicenses @() 
        Start-Sleep -Seconds 10
        $licenses = Get-MgUserLicenseDetail -UserId $matchedUser.Id

        #$linceses | ForEach-Object {if($_.skupartnumber -eq )}

        if ($licenses) {
            $licenses | Select-Object SkuPartNumber, ServicePlans | Format-Table -AutoSize
        } else {
            Write-Host "No licenses assigned." -ForegroundColor Yellow
        }
    }
    }
}
