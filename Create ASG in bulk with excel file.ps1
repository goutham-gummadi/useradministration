Connect-AzAccount
$filepath = "C:\Users\ext.goutham.gummadi\Lantern\Technology - Onboarding Automation files\Create bulk ASG.xlsx"
$Fileinfo = Import-Excel -Path $filepath

# Optional: Log file setup
$logFile = "C:\Temp\GroupCreationErrors.log"
if (-not (Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force | Out-Null
}

foreach ($group in $Fileinfo) {
    $SGName      = $group.AcceptableName
    $Description = $group.Description
    $Owner       = $group.Managedby

    # Skip if any value is null or empty
    if (-not ($SGName -and $Description -and $Owner)) {
        Write-Host "Skipping row with missing values" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "[$(Get-Date)] Skipped row: Missing required fields for group."
        continue
    }

    try {
        # Create the Azure AD Group
        New-AzADGroup -DisplayName $SGName -MailNickname $SGName -Description $Description 
    }
    catch {
        $msg = "[$(Get-Date)] Unable to create group '$SGName': $($_.Exception.Message)"
        Write-Host $msg -ForegroundColor Red
        Add-Content -Path $logFile -Value $msg
        continue
    }

    try {
        $groupinfo = (Get-AzADGroup -DisplayName $SGName).Id
        if (-not $groupinfo) {
            $msg = "[$(Get-Date)] Group not found after creation: $SGName"
            Write-Host $msg -ForegroundColor Yellow
            Add-Content -Path $logFile -Value $msg
            continue
        }

        try {
            $managerinfo = (Get-AzADUser -DisplayName $Owner).Id
            if ($managerinfo) {
                New-AzADGroupOwner -GroupId $groupinfo -OwnerId $managerinfo
            }
            else {
                $msg = "[$(Get-Date)] Manager not found: $Owner"
                Write-Host $msg -ForegroundColor Yellow
                Add-Content -Path $logFile -Value $msg
            }
        }
        catch {
            $msg = "[$(Get-Date)] Error retrieving manager info for '$Owner': $($_.Exception.Message)"
            Write-Host $msg -ForegroundColor Red
            Add-Content -Path $logFile -Value $msg
        }
    }
    catch {
        $msg = "[$(Get-Date)] Unable to retrieve group '$SGName': $($_.Exception.Message)"
        Write-Host $msg -ForegroundColor Red
        Add-Content -Path $logFile -Value $msg
    }
}