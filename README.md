# winssh-bootstrap

One command to make a new Windows machine reachable over SSH with no password —
for LAN dev use (e.g. letting a build tool on another machine use this PC's CPU/GPU).

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/bootstrap.ps1 | iex
```

Run in PowerShell (admin not required — it elevates itself). Does everything in one
pass: installs and starts `sshd` (via the standalone Win32-OpenSSH build, no Windows
Update dependency), sets it to auto-start, opens firewall port 22, authorizes a
trusted device's public key so future connections need no password, and prints the
connection info. Safe to run more than once — skips whatever's already done.

This is the one to use for any *new* machine. `setup-ssh.ps1`,
`setup-ssh-standalone.ps1`, and `authorize-key.ps1` below are the same steps kept
separate, for cases where you want just one of them.

## The individual scripts

### `setup-ssh.ps1` — Windows Update-backed OpenSSH feature

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh.ps1 | iex
```

Installs OpenSSH via the built-in optional feature (`Add-WindowsCapability`), starts
`sshd`, auto-start, firewall port 22. Can hang/crawl if Windows Update itself is slow
— see the standalone variant below if so.

### `setup-ssh-standalone.ps1` — no Windows Update dependency

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh-standalone.ps1 | iex
```

Downloads Microsoft's portable [Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
build (~5MB, straight from GitHub) to `C:\OpenSSH` and installs the service from that
instead. Same end result, different install path. Safe to run even if the other
script partially ran first.

### `authorize-key.ps1` — trust a device's key (skip the password after this)

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/authorize-key.ps1 | iex
```

Adds a public key to both locations OpenSSH might check (`authorized_keys` for
regular accounts, `administrators_authorized_keys` for accounts in the local
Administrators group) with correct ACLs, then restarts `sshd`. A public key alone
can't be used to reach the device it came from — it only lets that device *in* here
— so this is safe to publish/run without exposing anything.
