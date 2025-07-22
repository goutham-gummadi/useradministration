$Users= get-aduser -filter * -SearchBase "OU=Engineering,OU=People,DC=corp,DC=edhc,DC=com"
$GroupMemberships = Get-ADGroupMember -Identity SG_ORG_ITS
$Users | ForEach-Object{
$CurrentOUUser=$_
$GroupMemberships | ForEach-Object{if($_.SamAccountName -eq $CurrentOUUser.SamAccountname)
{
Write-Host "$($CurrentOUUser.DisplayName) is already a member of SG_ORG_ITS"
}
else
{
Add-ADGroupMember -Identity SG_ORG_ITS -Members $CurrentOUUser.SamAccountName
}
}
}