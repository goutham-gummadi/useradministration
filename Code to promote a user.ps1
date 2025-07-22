do {
    $SAM = Read-Host "Enter the SAM account name of the user you want to promote"

    try {
        $SAMADInfo = Get-ADUser -Identity $SAM -Properties * -ErrorAction Stop
        Write-Host "`n✅ Found user:"
        Write-Host "SAM:        $($SAMADInfo.SamAccountName)"
        Write-Host "Title:      $($SAMADInfo.Title)"
        Write-Host "Department: $($SAMADInfo.Department)"
        Write-Host "Manager:    $($SAMADInfo.Manager)"
    } catch {
        Write-Warning "❌ User not found. Please check the SAM account name."
        continue
    }

    # Collect promotion details
    $NewTitle      = Read-Host "Enter the new title of the user"
    $NewDepartment = Read-Host "Enter the new department (leave blank if unchanged)"
    $NewManager    = Read-Host "Enter the SAM of the new manager (leave blank if unchanged)"
    $EffectiveDate = Read-Host "Enter the promotion date"
    $JIRATicket    = Read-Host "Enter the JIRA ticket number"
    $Company       = Read-Host "Enter the company name (leave blank if unchanged)"

    # Construct info and description fields
    $Information   = "|| Promotion date: $EffectiveDate | JIRA Ticket: $JIRATicket ||"
    $UDescription  = "$NewTitle | $NewDepartment | $EffectiveDate"

    # Show summary
    Write-Host "`n📝 The following changes will be applied:"
    Write-Host "Title:      $NewTitle"
    Write-Host "Department: $NewDepartment"
    Write-Host "Manager:    $NewManager"
    Write-Host "Date:       $EffectiveDate"
    Write-Host "Company:    $Company"
    Write-Host "JIRA:       $JIRATicket"
    $Confirm = Read-Host "`nDo you want to proceed? (Y/N)"
    if ($Confirm.ToUpper() -ne "Y") {
        Write-Host "⏭ Skipping update for $SAM.`n"
        continue
    }

    try {
        # Build the parameter set dynamically
        $Parameters = @{
            Identity     = $SAMADInfo.SamAccountName
            Title        = $NewTitle
            Replace      = @{ info = $Information }
            Description  = $UDescription
            ErrorAction  = 'Stop'
        }

        if ($NewDepartment) { $Parameters['Department'] = $NewDepartment }

        if ($NewManager) {
            try {
                $ManagerUser = Get-ADUser -Identity $NewManager -Properties DistinguishedName
                $Parameters['Manager'] = $ManagerUser.DistinguishedName
            } catch {
                Write-Warning "⚠ Could not find manager '$NewManager'. Skipping manager update."
            }
        }

        if ($Company) { $Parameters['Company'] = $Company }

        # Perform the update
        Set-ADUser @Parameters
        Write-Host "`n✅ User updated successfully.`n"
        Start-Sleep -Seconds 10

        # Display updated user details
        Get-ADUser -Identity $SAMADInfo.SamAccountName -Properties * |
            Select-Object DisplayName, Title, Department, Manager, info, company, Description |
            Format-List
    } catch {
        Write-Error "`n❌ Failed to update the user: $_"
    }

    $Continue = Read-Host "`nDo you want to promote another user? (Y/N)"
} while ($Continue.ToUpper() -eq "Y")
