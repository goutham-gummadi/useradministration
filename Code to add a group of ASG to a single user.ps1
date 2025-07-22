$Groups = @("")

$User = ""

# Retrieve user information
$Userinfo = az ad user show --id $User --output json | ConvertFrom-Json

if ($Userinfo -eq $null) {
    Write-Host "Failed to retrieve user information for $User" -ForegroundColor Red
    return
}

# Iterate over each group
$Groups | ForEach-Object {
    $GroupName = $_

    # Retrieve group information
    $GroupInfo = az ad group show --group $GroupName --output json | ConvertFrom-Json

    if ($GroupInfo -eq $null) {
        Write-Host "Failed to retrieve group information for $GroupName" -ForegroundColor Yellow
        return
    }

    # Try to add the user to the group
    try {
        az ad group member add --group $GroupInfo.id --member-id $Userinfo.id
        Write-Host "Successfully added $($Userinfo.displayName) to $($GroupInfo.displayName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to add $($Userinfo.displayName) to the group $($GroupInfo.displayName): $($_.Exception.Message)" -ForegroundColor Red
    }
}
