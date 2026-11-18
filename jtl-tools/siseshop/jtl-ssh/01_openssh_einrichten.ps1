# OpenSSH-Zugang auf dem JTL-Server c10330 (nur Entwicklungszeit, Plan E-O)
# - Admin-Zugang fuer m.piper (statt RDP), nur Schluessel
# - Benutzer siseshop-tunnel: darf NUR auf 127.0.0.1:<SQL-Port> weiterleiten, keine Shell
# - SSH-Port 50022 nur fuer node1 (und optional eine feste Buero-IP)
# Vorher 00_pruefen.ps1 ausfuehren. Dann die Variablen unten fuellen und dieses Skript in PowerShell "Als Administrator" auf c10330 starten.

# ---------- Teil 1: einrichten ----------
$AdminUser  = 'mpiper'                               # lokales Admin-Konto, mit dem du dich anmeldest
$AdminKey   = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOJ/KxZXpYP10TRpuJc9gVRMK1kl0Dwc4ppCU3GYeom m.piper JTL c10330'         # Inhalt von ~/.ssh/jtl_admin.pub
$TunnelKey  = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQsaVGhqsjhQMJVY7KqrthpprjDh1Aeg2cs+mjkhCot siseshop-tunnel'            # Inhalt von ~/.ssh/siseshop_tunnel.pub
$SqlPort    = 50000                                            # aus 00_pruefen.ps1 (c10330: 50000, Stand 10.10.2026)
$AllowedIps = @('136.243.107.86')                              # node1; ggf. feste Buero-IP ergaenzen
$SshPort    = 50022                                            # 22 wird vor dem Server (ecomdata) gefiltert, J-22

$ErrorActionPreference = 'Stop'
if ($AdminUser -like 'HIER_*' -or $AdminKey -like '*AAAA...*' -or $TunnelKey -like '*AAAA...*') { throw 'Variablen oben noch nicht gefuellt - nichts geaendert' }
if (-not (Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue)) { throw "Lokales Konto $AdminUser fehlt - nichts geaendert" }

# 1) OpenSSH-Server installieren. Fehler 0x800f0954 (WSUS liefert keine Features on Demand, c10330 am 10.10.2026):
#    vorher HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing RepairContentServerSource=2 setzen, danach wieder entfernen
# (Server 2019/2022; bei 2025 schon vorhanden; 2016: MSI von github.com/PowerShell/Win32-OpenSSH)
if ((Get-WindowsCapability -Online -Name 'OpenSSH.Server*').State -ne 'Installed') { Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 }
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) { throw 'OpenSSH-Server nicht installiert (Dienst sshd fehlt)' }
Start-Service sshd; Stop-Service sshd                          # legt C:\ProgramData\ssh mit Hostschluesseln an

# 2) Firewall: nur erlaubte Quell-IPs
if (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -RemoteAddress $AllowedIps -Profile Any
    Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Get-NetFirewallPortFilter | Set-NetFirewallPortFilter -LocalPort $SshPort
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound `
        -Protocol TCP -LocalPort $SshPort -Action Allow -RemoteAddress $AllowedIps -Profile Any
}

# 3) Standard-Shell PowerShell statt cmd
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
    -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null

# 4) Admin-Schluessel (Datei darf nur Administratoren und SYSTEM gehoeren - per SID, sprachunabhaengig)
$sshDir = "$env:ProgramData\ssh"
Set-Content -Path "$sshDir\administrators_authorized_keys" -Value $AdminKey -Encoding ascii
icacls.exe "$sshDir\administrators_authorized_keys" /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'

# 5) Tunnel-Benutzer: Zufallspasswort, wird nie angezeigt und nie gebraucht
$bytes = New-Object byte[] 48
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$pw = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
if (-not (Get-LocalUser -Name 'siseshop-tunnel' -ErrorAction SilentlyContinue)) {
New-LocalUser -Name 'siseshop-tunnel' -Password $pw -PasswordNeverExpires -UserMayNotChangePassword `
    -Description 'Nur SSH-Tunnel Wawi-SQL (SiseShop-Dev)'   # max. 48 Zeichen
Add-LocalGroupMember -SID 'S-1-5-32-545' -Member 'siseshop-tunnel'   # "Benutzer" - kein RDP, kein Admin
}

# Schluessel mit Einschraenkung direkt im Schluessel (doppelt zur sshd_config)
New-Item -ItemType Directory -Path "$sshDir\tunnel_keys" -Force | Out-Null
Set-Content -Path "$sshDir\tunnel_keys\siseshop-tunnel" -Encoding ascii `
    -Value "restrict,port-forwarding,permitopen=`"127.0.0.1:$SqlPort`" $TunnelKey"
icacls.exe "$sshDir\tunnel_keys" /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)F' /grant '*S-1-5-18:(OI)(CI)F' /grant 'siseshop-tunnel:(OI)(CI)R'

# 6) sshd_config komplett neu (Sicherung der alten), ohne BOM
Copy-Item "$sshDir\sshd_config" "$sshDir\sshd_config.bak-$(Get-Date -Format yyyyMMdd)" -ErrorAction SilentlyContinue
@"
# Meesenburg - nur Schluessel, Weiterleitung nur wo noetig
Port $SshPort
AllowUsers $AdminUser siseshop-tunnel
AuthorizedKeysFile .ssh/authorized_keys
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
GSSAPIAuthentication no
AllowTcpForwarding no
AllowAgentForwarding no
X11Forwarding no
GatewayPorts no
PermitTunnel no
LoginGraceTime 30
MaxAuthTries 3
ClientAliveInterval 60
ClientAliveCountMax 3
LogLevel VERBOSE
Subsystem sftp sftp-server.exe

Match User $AdminUser
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
    AllowTcpForwarding local

Match User siseshop-tunnel
    AuthorizedKeysFile __PROGRAMDATA__/ssh/tunnel_keys/siseshop-tunnel
    AllowTcpForwarding local
    PermitOpen 127.0.0.1:$SqlPort
    PermitTTY no
    ForceCommand exit
"@ | Set-Content -Path "$sshDir\sshd_config" -Encoding ascii

# 7) Konfiguration pruefen, dann starten
& "$env:windir\System32\OpenSSH\sshd.exe" -t; if ($LASTEXITCODE -ne 0) { throw 'sshd_config fehlerhaft - sshd nicht gestartet' }
Set-Service sshd -StartupType Automatic
Restart-Service sshd                                           # auch bei erneutem Lauf die neue Konfiguration laden
Get-NetTCPConnection -State Listen -LocalPort $SshPort | Format-Table LocalAddress, LocalPort -AutoSize | Out-Host
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Get-NetFirewallAddressFilter | Format-List RemoteAddress | Out-Host

# Protokoll: Ereignisanzeige > Anwendungs- und Dienstprotokolle > OpenSSH > Operational
# Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 20

# ---------- Rueckbau ----------
# Stop-Service sshd; Set-Service sshd -StartupType Disabled
# Remove-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
# Remove-LocalUser -Name 'siseshop-tunnel'
# Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
