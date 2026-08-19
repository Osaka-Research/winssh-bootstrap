# winssh-bootstrap

One command to enable Windows OpenSSH Server (for LAN dev use — e.g. letting
a build tool on another machine SSH in to use this PC's CPU/GPU).

Run in PowerShell (admin not required — it elevates itself):

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh.ps1 | iex
```

Installs the OpenSSH Server optional feature, starts `sshd`, sets it to
auto-start, opens firewall port 22, and prints your Windows username + LAN
IP(s) to connect with.

## If that's stuck/slow (Windows Update dependency)

`setup-ssh.ps1` installs OpenSSH via the Windows Update-backed optional
feature (`Add-WindowsCapability`), which can hang or crawl if Windows Update
itself is slow. `setup-ssh-standalone.ps1` skips Windows Update entirely —
downloads Microsoft's portable [Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
build (~5MB, straight from GitHub) to `C:\OpenSSH` and installs the service
from that instead:

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/master/setup-ssh-standalone.ps1 | iex
```

Same end result (running, auto-starting `sshd` + open firewall port), different
install path. Safe to run even if the other script partially ran first.
