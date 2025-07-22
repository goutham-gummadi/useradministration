
$importfile = "C:\Users\ext.goutham.gummadi\OneDrive - Lantern\Desktop\Rough book\roughbook.xlsx"
$importdata = Import-Excel -Path $importfile

foreach ($User in $importdata) {
    if ([string]::IsNullOrWhiteSpace($User.name)) {
        continue  # Skip blank rows
    }

    $UPN = $User.name

    try {
        $UserInfo = Get-MgUser -Filter "userPrincipalName eq '$UPN'" -Property Id, DisplayName -ErrorAction Stop

        if (-not $UserInfo -or -not $UserInfo.Id) {
            Write-Warning "User $UPN not found or missing ID in Azure AD"
            continue
        }

        $Groups = @("asg_lc_eng_github_sso_user","asg_lc_ct_datadog_SSO")

    foreach ($group in $Groups) {
        try {
            # Check if user is already in the group
            $isMember = az ad group member check --group $group --member-id $UserInfo.Id --query value -o tsv

            if ($isMember -eq "true") {
                Write-Host "ℹ️ User '$($UserInfo.DisplayName)' is already a member of '$group'. Skipping."
                continue
            }

            # Add user to group
            az ad group member add --group $group --member-id $UserInfo.Id
            Write-Host "✅ User '$($UserInfo.DisplayName)' added to group '$group'."
        }
        catch {
            Write-Host "❌ Error adding '$UPN' to '$group': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    }
    catch {
        Write-Warning "Error retrieving user '$UPN': $($_.Exception.Message)"
    }
}
