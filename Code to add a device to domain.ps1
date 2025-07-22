# Retrieve the current device serial number
$CurrentDeviceSerialNumber = (Get-CimInstance Win32_BIOS).SerialNumber

# Create new device name as per naming convention
$DeviceName = "EDHC" + $CurrentDeviceSerialNumber + "$"

# Add device to domain
try {
    Write-Host "Joining device to domain..." -ForegroundColor Cyan
    Add-Computer -DomainName "" `
                 -NewName $DeviceName `
                 -OUPath "OU=EndUserComputers,DC=corp,DC=edhc,DC=com" `
                 -Credential (Get-Credential) `
                 -Restart:$true
    Write-Host "Device successfully joined to domain as '$DeviceName'." -ForegroundColor Green
}
catch {
    Write-Host "Error joining device to domain: $_" -ForegroundColor Red
    exit
}


____________________________________________________________________________________________________________________________________________________
____________________________________________________________________________________________________________________________________________________

# Add the domain-joined device to the 'Intune Enrollment' group
try {
    Write-Host "Adding device '$DeviceName' to 'Intune Enrollment' group..." -ForegroundColor Cyan
    Add-ADGroupMember -Identity "Intune Enrollment" -Members $DeviceName -Confirm:$false
    Write-Host "Device '$DeviceName' successfully added to 'Intune Enrollment' group." -ForegroundColor Green
}
catch {
    Write-Host "Error adding device to group: $_" -ForegroundColor Red
}
