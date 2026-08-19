# Osaka-Research / winssh-bootstrap -- standalone variant
# Installs Microsoft's portable Win32-OpenSSH build instead of the Windows Update
# "OpenSSH Server" optional feature. Use this if Add-WindowsCapability is stuck/slow --
# this downloads a small zip directly from GitHub and skips Windows Update entirely.
# Run as Administrator.

$ErrorActionPreference = 'Stop'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-launching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -Command `"irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh-standalone.ps1 | iex`""
    exit
}

$installDir = "C:\OpenSSH"
$zipPath = "$env:TEMP\OpenSSH-Win64.zip"

Write-Host "Downloading Win32-OpenSSH..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip" -OutFile $zipPath

Write-Host "Extracting to $installDir ..." -ForegroundColor Cyan
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath -Force

$sshDir = Get-ChildItem -Path $installDir -Directory | Select-Object -First 1
Set-Location $sshDir.FullName

Write-Host "Installing sshd service..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File .\install-sshd.ps1

Write-Host "Starting sshd and enabling auto-start..." -ForegroundColor Cyan
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

Write-Host "Opening firewall port 22..." -ForegroundColor Cyan
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null

# Fixes a common Win32-OpenSSH gotcha: PowerShell as default shell needs an explicit registry entry
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null

Write-Host ""
Write-Host "Done. Connection info:" -ForegroundColor Green
Write-Host "  Username: $env:USERNAME"
Write-Host "  IP address(es):"
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' }).IPAddress | ForEach-Object { Write-Host "    $_" }
Write-Host ""
Write-Host "sshd now runs as a background service. Test locally with: ssh $env:USERNAME@localhost"
