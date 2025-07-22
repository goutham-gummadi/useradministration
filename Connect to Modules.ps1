Connect-ExchangeOnline
Connect-AzAccount
Connect-MgGraph -scopes "User.read.all"
Connect-MgGraph -scopes "group.readwrite.all"
Connect-MgGraph -scopes "sites.read.all"
Start-Process msedge.exe "https://login.microsoftonline.com/common/oauth2/deviceauth"
az login --use-device-code