$csvpath= ""
$csvdata= Import-Csv -Path $csvpath
$targetpath= ""

foreach($device in $csvdata){
$devicename= $device.DeviceName
try{
Move-ADObject -Identity $devicename -TargetPath $targetpath -ErrorAction SilentlyContinue
}
catch{
Write-Host "$_"
}
}
