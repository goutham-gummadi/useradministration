function Find-Manager {
    param(
        [Parameter(Mandatory = $false)]
        [string]$InitialManagerSAM
    )

    while ($true) {
        if (-not $InitialManagerSAM) {
            $InitialManagerSAM = Read-Host "Enter new manager SAM (or 'Quit' to exit)"
        }

        if ($InitialManagerSAM -ceq "Quit") {
            Write-Host "Exiting manager lookup."
            return $null
        }

        $ManagerInfo = Get-ADUser -Identity $InitialManagerSAM -Properties * -ErrorAction SilentlyContinue |
                       Select-Object SamAccountName, UserPrincipalName, DistinguishedName

        if ($ManagerInfo) {
            return $ManagerInfo.DistinguishedName
        } else {
            Write-Warning "Manager with SAM account '$InitialManagerSAM' not found. Please try again."
            $InitialManagerSAM = $null
        }
    }
}

do {
    $UserSAM = Read-Host "Enter SAM of the user who is getting transferred/promoted (or 'Quit' to exit)"
    if ($UserSAM -ceq "Quit") {
        Write-Host "Exiting user transfer/promotion program."
        break
    }

    try {
        $UserInfo = Get-ADUser -Identity $UserSAM -Properties DisplayName, Description, Title, Department, Manager, Info -ErrorAction Stop
        Write-Host "`nCurrent user information:" -ForegroundColor DarkCyan
        $UserInfo | Format-List DisplayName, Description, Title, Department, Manager, Info
    } catch {
        Write-Warning "Unable to find user account '$UserSAM'."
        continue
    }

    $NewManagerDN = Find-Manager
    if (-not $NewManagerDN) { continue }

    $NewTitle = Read-Host "Enter new title"
    $NewDepartment = Read-Host "Enter new department"
    $JiraTicket = Read-Host "Enter Jira Ticket number"

    if (-not $NewTitle -or -not $NewDepartment -or -not $JiraTicket) {
        Write-Warning "All fields are required. Please try again."
        continue
    }

    $today = Get-Date -Format "MM-dd-yyyy"
    $NewDescription = "$NewTitle | $JiraTicket | $today"
    $NewInfo = "$($UserInfo.Info) || New transferred title - $NewTitle | Jira Ticket - $JiraTicket ||"

    try {
        Set-ADUser -Identity $UserSAM -Title $NewTitle -Department $NewDepartment -Manager $NewManagerDN -Description $NewDescription
        Set-ADUser -Identity $UserSAM -Replace @{Info = $NewInfo}

        Start-Sleep -Seconds 10
        $UpdatedUser = Get-ADUser -Identity $UserSAM -Properties * | Select-Object DisplayName, Description, Title, Department, Manager, Info
        Write-Host "`nUpdated user information:" -ForegroundColor Cyan
        $UpdatedUser | Format-List
    } catch {
        Write-Error "An error occurred while updating the user."
    }

    $Continue = Read-Host "Do you want to transfer another user (Y/N)?"
} while ($Continue -ceq "Y")

Write-Host "Script execution completed."
