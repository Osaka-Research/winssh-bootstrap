# winssh-bootstrap

One command to enable Windows OpenSSH Server (for LAN dev use — e.g. letting
a build tool on another machine SSH in to use this PC's CPU/GPU).

Run in PowerShell (admin not required — it elevates itself):

```powershell
irm https://raw.githubusercontent.com/Osaka-Research/winssh-bootstrap/main/setup-ssh.ps1 | iex
```

Installs the OpenSSH Server optional feature, starts `sshd`, sets it to
auto-start, opens firewall port 22, and prints your Windows username + LAN
IP(s) to connect with.
