# Osaka-Research / winssh-bootstrap -- bootstrap
# One command for a brand-new machine: installs+starts sshd (via the standalone
# Win32-OpenSSH build -- no Windows Update dependency), opens firewall port 22,
# then authorizes this phone's key so future connections need no password.
# Combines setup-ssh-standalone.ps1 + authorize-key.ps1. Safe to run more than once.
# Run as Administrator (self-elevates).

$ErrorActionPreference = 'Stop'
$pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiJ6+FCsWhEOQ57LyeNav9xnBC5NpeE/DBrOSktzpRy clicky-bridge"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-launching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -Command `"irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/bootstrap.ps1 | iex`""
    exit
}

# ── 1. Install + start sshd (standalone Win32-OpenSSH, skips Windows Update) ──

$existing = Get-Service sshd -ErrorAction SilentlyContinue
if (-not $existing) {
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

    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null
} else {
    Write-Host "sshd already installed -- skipping download/reinstall." -ForegroundColor Yellow
}

if ((Get-Service sshd).Status -ne 'Running') {
    Write-Host "Starting sshd..." -ForegroundColor Cyan
    Start-Service sshd
}
Set-Service -Name sshd -StartupType Automatic

if (-not (Get-NetFirewallRule -Name sshd -ErrorAction SilentlyContinue)) {
    Write-Host "Opening firewall port 22..." -ForegroundColor Cyan
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

# ── 2. Authorize this phone's key -- no password on future connections ──

Write-Host "Authorizing key..." -ForegroundColor Cyan

$userKeyDir = "$env:USERPROFILE\.ssh"
$userKeyFile = "$userKeyDir\authorized_keys"
New-Item -ItemType Directory -Path $userKeyDir -Force | Out-Null
if (-not (Test-Path $userKeyFile) -or -not (Select-String -Path $userKeyFile -Pattern ([regex]::Escape($pubkey)) -Quiet)) {
    Add-Content -Path $userKeyFile -Value $pubkey
}
icacls $userKeyFile /inheritance:r /grant:r "$($env:USERNAME):F" "SYSTEM:F" "Administrators:F" | Out-Null

$adminKeyFile = "C:\ProgramData\ssh\administrators_authorized_keys"
New-Item -ItemType Directory -Path "C:\ProgramData\ssh" -Force | Out-Null
if (-not (Test-Path $adminKeyFile) -or -not (Select-String -Path $adminKeyFile -Pattern ([regex]::Escape($pubkey)) -Quiet)) {
    Add-Content -Path $adminKeyFile -Value $pubkey
}
icacls $adminKeyFile /inheritance:r /grant:r "SYSTEM:F" "Administrators:F" | Out-Null

Restart-Service sshd

# ── 3. Done ──

Write-Host ""
Write-Host "Done. Connection info:" -ForegroundColor Green
Write-Host "  Username: $env:USERNAME"
Write-Host "  IP address(es):"
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' }).IPAddress | ForEach-Object { Write-Host "    $_" }
Write-Host ""
Write-Host "sshd runs as a background service, auto-starts, and this device's key is trusted." -ForegroundColor Green
Write-Host "Future connections from it need no password and no script." -ForegroundColor Green
