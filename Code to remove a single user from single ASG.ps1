az login
do { 
$UserName= Read-Host "Enter name of the user you want to remove from a SG"
$SGName= Read-Host "Enter name of the SG"
if ($UserName -ne $null -and $SGName -ne $null) {
    az ad group member remove --group $(az ad group show --group $SGName --query id -o tsv) --member $(az ad user list --filter "DisplayName eq '$UserName'" --query "[0].id" -o tsv)
}
$Continue= Read-Host "Do you want to remove another user from the this Group (Y/N)"   
} while (
    $Continue -eq "Y"
)