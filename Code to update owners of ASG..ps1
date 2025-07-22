<#$newGroupOwner =@{
  "@odata.id"= "https://graph.microsoft.com/v1.0/users/{6ef88a96-d57e-4ae6-a8ab-7168ae01158b}"
  }
  #>
  # Get groups that start with 'asg_dm_snowflake'
$groups = Get-MgGroup -Filter "startswith(displayName,'')" -Property Id, DisplayName

# Loop over each group and add the new owner
<#foreach ($group in $groups) {
    Write-Host "Adding owner to group: $($group.DisplayName) [$($group.Id)]" -ForegroundColor Cyan
    New-MgGroupOwnerByRef -GroupId $group.Id -BodyParameter $newGroupOwner
}#>

# Verify owners after addition
foreach ($group in $groups) {
    Write-Host "`nOwners for group: $($group.DisplayName)" -ForegroundColor Yellow

    $owners = Get-MgGroupOwner -GroupId $group.Id

    foreach ($owner in $owners) {

            $user = Get-MgUser -UserId $owner.Id -Property DisplayName
            Write-Host "- $($user.DisplayName)"
    }
}
