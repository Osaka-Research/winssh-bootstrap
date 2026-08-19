# Osaka-Research / winssh-bootstrap -- authorize-key
# Adds a phone's SSH public key to this Windows account, so future connections
# from that device need no password. Writes to both locations OpenSSH might check
# (regular authorized_keys and the administrators_authorized_keys sshd uses for
# admin accounts) with correct ACLs -- no need to know in advance which applies.
# Run as Administrator (self-elevates).

$pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiJ6+FCsWhEOQ57LyeNav9xnBC5NpeE/DBrOSktzpRy clicky-bridge"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-launching as Administrator..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -Command `"irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/authorize-key.ps1 | iex`""
    exit
}

# 1) Regular user authorized_keys -- used when this account isn't a member of Administrators.
$userKeyDir = "$env:USERPROFILE\.ssh"
$userKeyFile = "$userKeyDir\authorized_keys"
New-Item -ItemType Directory -Path $userKeyDir -Force | Out-Null
if (-not (Test-Path $userKeyFile) -or -not (Select-String -Path $userKeyFile -Pattern ([regex]::Escape($pubkey)) -Quiet)) {
    Add-Content -Path $userKeyFile -Value $pubkey
}
icacls $userKeyFile /inheritance:r /grant:r "$($env:USERNAME):F" "SYSTEM:F" "Administrators:F" | Out-Null

# 2) administrators_authorized_keys -- this is the one sshd actually reads if this
#    account IS a member of Administrators. Written unconditionally too, harmless if not needed.
$adminKeyFile = "C:\ProgramData\ssh\administrators_authorized_keys"
New-Item -ItemType Directory -Path "C:\ProgramData\ssh" -Force | Out-Null
if (-not (Test-Path $adminKeyFile) -or -not (Select-String -Path $adminKeyFile -Pattern ([regex]::Escape($pubkey)) -Quiet)) {
    Add-Content -Path $adminKeyFile -Value $pubkey
}
icacls $adminKeyFile /inheritance:r /grant:r "SYSTEM:F" "Administrators:F" | Out-Null

Write-Host ""
Write-Host "Key authorized. Restarting sshd so it re-reads the files..." -ForegroundColor Cyan
Restart-Service sshd

Write-Host "Done -- future SSH connections from this device need no password." -ForegroundColor Green
