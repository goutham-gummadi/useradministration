# Get existing PATH
$CurrentuserSam= ""
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

# Append the new path if it’s not already present
$newPath = "C:\Users\$CurrentuserSam\AppData\Local\Microsoft\WindowsApps"
if ($currentPath -notlike "*$newPath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$newPath", "User")
    Write-Host "Path updated for current user." -ForegroundColor Green
} else {
    Write-Host "Path already contains the specified value." -ForegroundColor Yellow
}
