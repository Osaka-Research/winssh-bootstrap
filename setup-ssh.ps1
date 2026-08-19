# Osaka-Research / winssh-bootstrap
# Enables Windows OpenSSH Server, sets it to auto-start, opens the firewall port,
# and prints the username + LAN IP(s) to connect with. Run as Administrator.

$ErrorActionPreference = 'SilentlyContinue'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-launching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -Command `"irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh.ps1 | iex`""
    exit
}

Write-Host "Installing OpenSSH Server..." -ForegroundColor Cyan
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null

Write-Host "Starting sshd and enabling auto-start..." -ForegroundColor Cyan
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

Write-Host "Opening firewall port 22..." -ForegroundColor Cyan
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host "Done. Connection info:" -ForegroundColor Green
Write-Host "  Username: $env:USERNAME"
Write-Host "  IP address(es):"
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' }).IPAddress | ForEach-Object { Write-Host "    $_" }
Write-Host ""
Write-Host "Leave this window open or close it -- sshd now runs as a background service."
