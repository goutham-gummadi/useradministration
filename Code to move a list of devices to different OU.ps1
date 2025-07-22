$csvpath= "C:\Users\ext.goutham.gummadi\Downloads\Move to 120.csv"
$csvdata= Import-Csv -Path $csvpath
$targetpath= "OU=Offline 120\+,OU=Offboarded Users (No Sync),DC=corp,DC=edhc,DC=com"

foreach($device in $csvdata){
$devicename= $device.DeviceName
try{
Move-ADObject -Identity $devicename -TargetPath $targetpath -ErrorAction SilentlyContinue
}
catch{
Write-Host "$_"
}
}