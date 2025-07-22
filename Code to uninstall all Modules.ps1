# Get all installed modules
$AllModules = Get-InstalledModule

# Iterate and uninstall each module
foreach ($Module in $AllModules) {
    try {
        Write-Host "Uninstalling module: $($Module.Name)" -ForegroundColor Cyan
        Uninstall-Module -Name $Module.Name -AllVersions -Force -ErrorAction Stop
    } catch {
        Write-Warning "Failed to uninstall module: $($Module.Name). Error: $_"
    }
}
Write-Host "All modules uninstalled successfully!" -ForegroundColor Green
