# OpenSSH-Admin-Zugang auf dem JTL-Testserver c22910 (ecomdata) - nur von node1 (18.11.2026, M. Piper)
# Warum: Firewall-/Dienstpflege ohne RDP, wie bei c10330. Bewusst nur Admin (kein Tunnel-Benutzer), nur Schluessel, Port 50022, nur node1.
# Uebergang: node1-3 werden gekuendigt -> Ersatzweg siehe sise-docs/shop/TODO.md "Zugang zu den ecomdata-Servern ohne node1".
#
# Vorher: OpenSSH-Win64-<Version>.msi von https://github.com/PowerShell/Win32-OpenSSH/releases in C:\Users\mpiper\Downloads legen
#   (Windows-Feature scheitert auf c22910 am WSUS, 19.11.2026).
# Ausfuehren: per RDP als mpiper anmelden, Notepad -> Inhalt einfuegen -> speichern als C:\Users\mpiper\ssh_einrichten.ps1
#   PowerShell "Als Administrator":  powershell -ExecutionPolicy Bypass -File C:\Users\mpiper\ssh_einrichten.ps1
# Zusaetzlich im ecomdata-Portal (Firewall c22910): eingehend TCP 50022 nur von 136.243.107.86 (bei c10330 noetig, sonst Zeitueberschreitung).

$AdminUser  = 'mpiper'
$AdminKey   = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOJ/KxZXpYP10TRpuJc9gVRMK1kl0Dwc4ppCU3GYeom m.piper JTL c10330'   # ~/.ssh/jtl_admin.pub
$AllowedIps = @('136.243.107.86')   # node1
$SshPort    = 50022

$ErrorActionPreference = 'Stop'
$ts = Get-Date -Format yyyyMMdd-HHmmss
if (-not (Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue)) { throw "Lokales Konto $AdminUser fehlt - nichts geaendert" }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'PowerShell nicht "Als Administrator" gestartet - nichts geaendert' }

# 0) Firewall sichern
$dir = "$env:USERPROFILE\firewall-sicherung"; New-Item -ItemType Directory -Force $dir | Out-Null
netsh advfirewall export "$dir\firewall-$ts.wfw" | Out-Null
"Firewall gesichert: $dir\firewall-$ts.wfw"

# 1) OpenSSH-Server installieren - Reihenfolge:
#    a) Dienst sshd schon da -> nichts installieren
#    b) MSI von GitHub (PowerShell/Win32-OpenSSH, OpenSSH-Win64-*.msi) im Download-Ordner von mpiper -> damit installieren.
#       Bevorzugt auf c22910: Das Windows-Feature scheiterte dort am WSUS (19.11.2026), und an der Update-Steuerung
#       von ecomdata wollen wir nichts drehen.
#    c) sonst Windows-Feature (scheitert hinter WSUS meist mit 0x800f0954)
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
    $msi = Get-ChildItem "$env:USERPROFILE\Downloads", (Split-Path -Parent $PSCommandPath) -Filter 'OpenSSH-Win64-*.msi' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($msi) {
        "Installiere $($msi.FullName) (nur Server)"
        $p = Start-Process msiexec.exe -ArgumentList "/i `"$($msi.FullName)`" ADDLOCAL=Server /qn /norestart /l*v `"$dir\openssh-msi-$ts.log`"" -Wait -PassThru
        if ($p.ExitCode -notin 0, 3010) { throw "MSI-Installation fehlgeschlagen (ExitCode $($p.ExitCode), Log $dir\openssh-msi-$ts.log)" }
    } else {
        try { Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null }
        catch { throw "Windows-Feature nicht installierbar ($($_.Exception.Message)). MSI OpenSSH-Win64-*.msi von github.com/PowerShell/Win32-OpenSSH/releases in den Download-Ordner legen und erneut starten." }
    }
}
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) { throw 'OpenSSH-Server nicht installiert (Dienst sshd fehlt)' }
# Ordner der Programme aus dem Dienst lesen: Windows-Feature (System32\OpenSSH) oder MSI von GitHub (Program Files\OpenSSH)
$sshExe = ((Get-CimInstance Win32_Service -Filter "Name='sshd'").PathName -replace '"', '' -replace '\s+-.*$', '').Trim()
$sshBin = Split-Path $sshExe
"OpenSSH vorhanden: $sshExe"
Start-Service sshd; Stop-Service sshd   # legt C:\ProgramData\ssh mit Hostschluesseln an

# 2) Firewall: nur node1, nur Port 50022 (die Standardregel oeffnet sonst 22 fuer alle)
if (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -RemoteAddress $AllowedIps -Profile Any -Enabled True
    Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Get-NetFirewallPortFilter | Set-NetFirewallPortFilter -LocalPort $SshPort
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound `
        -Protocol TCP -LocalPort $SshPort -Action Allow -RemoteAddress $AllowedIps -Profile Any | Out-Null
}
# Weitere Freigaben fuer Port 22 (legt z. B. das MSI an) abschalten - sshd lauscht nur noch auf 50022
Get-NetFirewallPortFilter -Protocol TCP | Where-Object { ($_.LocalPort -join ',') -eq '22' } | Get-NetFirewallRule |
    Where-Object { $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow' -and $_.Enabled -eq 'True' -and $_.Name -ne 'OpenSSH-Server-In-TCP' } |
    ForEach-Object { "Regel fuer Port 22 abgeschaltet: $($_.DisplayName)"; $_ | Disable-NetFirewallRule }

# 3) Standard-Shell PowerShell statt cmd
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
    -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null

# 4) Admin-Schluessel (Datei darf nur Administratoren und SYSTEM gehoeren - per SID, sprachunabhaengig)
$sshDir = "$env:ProgramData\ssh"
Set-Content -Path "$sshDir\administrators_authorized_keys" -Value $AdminKey -Encoding ascii
icacls.exe "$sshDir\administrators_authorized_keys" /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' | Out-Null

# 5) sshd_config neu (Sicherung der alten), nur Schluessel, nur mpiper, keine Weiterleitungen
Copy-Item "$sshDir\sshd_config" "$sshDir\sshd_config.bak-$ts" -ErrorAction SilentlyContinue
@"
# Win32-OpenSSH 10.x bricht bei GSSAPIAuthentication, X11Forwarding, PermitTunnel ab (auf Windows nicht unterstuetzt, c22910 19.11.2026)
# Meesenburg - nur Admin per Schluessel, nur von node1 (Firewall), keine Weiterleitungen
Port $SshPort
AllowUsers $AdminUser
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
AllowTcpForwarding no
AllowAgentForwarding no
GatewayPorts no
LoginGraceTime 30
MaxAuthTries 3
ClientAliveInterval 60
ClientAliveCountMax 3
LogLevel VERBOSE
Subsystem sftp sftp-server.exe

Match User $AdminUser
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
"@ | Set-Content -Path "$sshDir\sshd_config" -Encoding ascii

# 6) Pruefen, starten, Ergebnis zeigen
& "$sshBin\sshd.exe" -t; if ($LASTEXITCODE -ne 0) { throw 'sshd_config fehlerhaft - sshd nicht gestartet' }
Set-Service sshd -StartupType Automatic
Restart-Service sshd
"--- lauscht ---"; Get-NetTCPConnection -State Listen -LocalPort $SshPort | Format-Table LocalAddress, LocalPort -AutoSize | Out-String
"--- Firewall ---"; Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Get-NetFirewallAddressFilter | Format-List RemoteAddress | Out-String
"--- Hostschluessel (an Claude/Mac zum Abgleich) ---"
& "$sshBin\ssh-keygen.exe" -lf "$sshDir\ssh_host_ed25519_key.pub"

# Protokoll: Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 20
# ---------- Rueckbau ----------
# Stop-Service sshd; Set-Service sshd -StartupType Disabled; Remove-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
# Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
