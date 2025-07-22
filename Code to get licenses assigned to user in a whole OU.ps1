# Get users from the specific OU
$userinfo = Get-ADUser -Filter * -SearchBase "OU=Service accounts,OU=Service Admins,DC=corp,DC=edhc,DC=com" -SearchScope Subtree -Properties SamAccountName, UserPrincipalName

# Loop through each user
$userinfo | ForEach-Object {
    $upn = $_.UserPrincipalName
    $sam = $_.SamAccountName

    if ($upn) {
        try {
            $userAzLicense = Get-MgUserLicenseDetail -UserId $upn | Select-Object -ExpandProperty SkuPartNumber

            if ($userAzLicense) {
                Write-Host "User: $sam" -ForegroundColor Cyan
                Write-Host "License(s):"
                $userAzLicense | ForEach-Object{
                
                Write-Host "$_" -ForegroundColor Green
                }
            }
        } catch {
            Write-Warning "Could not retrieve license for $upn"
        }
    } else {
        Write-Warning "No UserPrincipalName for $sam"
    }
}
