<#
.SYNOPSIS
  Rolliert die Passwörter aller aktiven lokalen Konten auf dem JTL-Server (c10330) - außer den ausgenommenen.

.DESCRIPTION
  Standard ist ein Probelauf: zeigt Konten, Gruppen, letzte Anmeldung, aktive Sitzungen und Abhängigkeiten
  (Dienste und geplante Aufgaben, die mit dem Kontopasswort laufen). Erst mit -Apply wird geändert.
  Neue Passwörter (24 Zeichen) landen in einer CSV im aktuellen Ordner, lesbar nur für Prozesskonto und angemeldetes Konto.
  -> Sofort in den Passwortmanager übernehmen und die Datei danach löschen.

  Mit -UpdateDependencies werden Dienste und geplante Aufgaben, die mit einem rollierten Konto laufen,
  auf das neue Passwort umgestellt (ohne Neustart der Dienste).

  Achtung: Bestehende RDP-Sitzungen bleiben nach dem Passwortwechsel bestehen. Wer ausgesperrt werden soll,
  muss zusätzlich abgemeldet werden (logoff <ID>) - NICHT bei der Sitzung, in der der JTL-Worker läuft.

.EXAMPLE
  # Probelauf (ändert nichts)
  .\rotate_local_passwords.ps1

.EXAMPLE
  # Ausführen (mpiper, cpsadmin, Administrator, IcingaUser bleiben immer unverändert)
  .\rotate_local_passwords.ps1 -Apply -UpdateDependencies

  Meesenburg, 12.10.2026 - Teil von Bericht 12 (Rotation und Aussperrung), Abschnitt 3.2
#>
[CmdletBinding()]
param(
    # Zusätzlich auszunehmende Konten (mpiper und die ecomdata-Konten sind immer geschützt, siehe $protected)
    [string[]] $Exclude = @(),
    [switch] $Apply,
    [switch] $UpdateDependencies,
    # Auch das angemeldete Konto rollieren (Sitzung bleibt bestehen, neues Passwort steht in der CSV)
    [switch] $IncludeInteractive,
    [int] $Length = 24
)

$ErrorActionPreference = 'Stop'

# --- Voraussetzungen ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Bitte PowerShell als Administrator starten.' }

if ($PSVersionTable.PSEdition -eq 'Core') {
    # In PowerShell 7 läuft das LocalAccounts-Modul nur über die Windows-PowerShell-Kompatibilität
    Import-Module Microsoft.PowerShell.LocalAccounts -UseWindowsPowerShell -WarningAction SilentlyContinue
}

# Immer geschützt (Vorgabe 12.10.2026): eigenes Konto und Konten des Hosters ecomdata
$protected = 'mpiper', 'cpsadmin', 'Administrator', 'IcingaUser'
$Exclude = @($Exclude) + $protected | Select-Object -Unique

# Prozesskonto (bei "Als Administrator ausführen" mit fremden Zugangsdaten z. B. useradmin) und angemeldetes Konto
$me = $env:USERNAME
$interactive = (Get-CimInstance Win32_Process -Filter "Name='explorer.exe' AND SessionId=$((Get-Process -Id $PID).SessionId)" |
    Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner).User
Write-Host "Skript läuft als: $me | angemeldet in dieser Sitzung: $interactive" -ForegroundColor DarkGray
if ($Exclude -notcontains $me) {
    Write-Warning ("Das Prozesskonto '$me' wird mit rolliert. Die laufende Sitzung bleibt bestehen; " +
        "für spätere Admin-Aufgaben das neue Passwort verwenden.")
}
# Das angemeldete Konto (der Mensch vor dem Bildschirm) wird immer geschützt
if ($interactive -and $Exclude -notcontains $interactive) {
    if ($IncludeInteractive) {
        Write-Warning "Das angemeldete Konto '$interactive' wird mit rolliert (-IncludeInteractive). Neues Passwort sofort aus der CSV übernehmen."
    } else {
        Write-Host "Angemeldetes Konto '$interactive' wird automatisch ausgenommen (mitrollieren: -IncludeInteractive)." -ForegroundColor Yellow
        $Exclude += $interactive
    }
}
# Eingebaute bzw. deaktivierte Systemkonten nie anfassen
$systemAccounts = 'Guest', 'Gast', 'DefaultAccount', 'WDAGUtilityAccount'

# Konten mit bekanntem Risiko (Bericht 10, 6.10) - werden im Probelauf markiert
$risk = @{
    'useradmin'     = 'JTL-Worker läuft in dieser Sitzung; Port-Reservierung JTL-REST; evtl. geplante Aufgaben'
    'cpsadmin'      = 'Konto von ecomdata (Hoster) - vorher mit ecomdata abstimmen'
    'Administrator' = 'Eingebautes Admin-Konto (evtl. ecomdata) - vorher abstimmen'
    'IcingaUser'    = 'Monitoring von ecomdata - kann bei Passwortwechsel ausfallen'
}

# --- Passwortgenerator (kryptografisch, ohne verwechselbare Zeichen) ---------------------------
function New-StrongPassword([int] $len) {
    $sets = @('ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnpqrstuvwxyz', '23456789', '!#%+=?@_-')
    $all = -join $sets
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $pick = {
        param($chars)
        $b = [byte[]]::new(4); $rng.GetBytes($b)
        $chars[[BitConverter]::ToUInt32($b, 0) % $chars.Length]
    }
    $chars = [System.Collections.Generic.List[char]]::new()
    foreach ($set in $sets) { $chars.Add((& $pick $set)) }            # je Klasse mindestens ein Zeichen
    while ($chars.Count -lt $len) { $chars.Add((& $pick $all)) }
    # mischen
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $b = [byte[]]::new(4); $rng.GetBytes($b)
        $j = [BitConverter]::ToUInt32($b, 0) % ($i + 1)
        $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
    }
    -join $chars
}

# --- Bestandsaufnahme --------------------------------------------------------------------------
$computer = $env:COMPUTERNAME
$services = Get-CimInstance Win32_Service
$tasks = Get-ScheduledTask
$adminMembers = @(Get-LocalGroupMember -Group 'Administratoren' -ErrorAction SilentlyContinue) +
                @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue) |
                ForEach-Object { ($PSItem.Name -split '\\')[-1] }
$rdpMembers = @(Get-LocalGroupMember -Group 'Remotedesktopbenutzer' -ErrorAction SilentlyContinue) +
              @(Get-LocalGroupMember -Group 'Remote Desktop Users' -ErrorAction SilentlyContinue) |
              ForEach-Object { ($PSItem.Name -split '\\')[-1] }

function Get-Dependencies([string] $user) {
    $patterns = @(".\$user", "$computer\$user", $user)
    $svc = $services | Where-Object { $patterns -contains $PSItem.StartName }
    $tsk = $tasks | Where-Object {
        $uid = $PSItem.Principal.UserId
        $uid -and ($patterns -contains $uid -or $uid -like "*\$user")
    }
    [pscustomobject]@{ Services = @($svc); Tasks = @($tsk) }
}

Write-Host "`n=== Automatische Anmeldung (Autologon) ===" -ForegroundColor Cyan
$winlogon = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
if ($winlogon.AutoAdminLogon -eq '1') {
    Write-Warning ("Autologon aktiv für '$($winlogon.DefaultUserName)'" +
        $(if ($winlogon.DefaultPassword) { ' (Passwort im Klartext in der Registry!)' } else { ' (Passwort als LSA-Secret)' }) +
        ' - nach dem Rollieren dieses Kontos startet die Anmeldung beim Neustart nicht mehr. Mit Sysinternals Autologon neu setzen.')
} else { Write-Host 'nicht aktiv' }

Write-Host "`n=== Aktive Sitzungen (query user) ===" -ForegroundColor Cyan
try { query user 2>$null } catch { Write-Host '(keine Ausgabe)' }

$candidates = Get-LocalUser | Where-Object {
    $PSItem.Enabled -and $systemAccounts -notcontains $PSItem.Name -and $Exclude -notcontains $PSItem.Name
}

Write-Host "`n=== Konten, die rolliert werden ===" -ForegroundColor Cyan
$plan = foreach ($u in $candidates) {
    $dep = Get-Dependencies $u.Name
    [pscustomobject]@{
        Konto          = $u.Name
        Admin          = $adminMembers -contains $u.Name
        RDP            = $rdpMembers -contains $u.Name
        LetzteAnmeldung = $u.LastLogon
        PasswortGesetzt = $u.PasswordLastSet
        Dienste        = ($dep.Services.Name -join ', ')
        Aufgaben       = ($dep.Tasks | ForEach-Object { "$($PSItem.TaskPath)$($PSItem.TaskName) [$($PSItem.Principal.LogonType)]" }) -join ', '
        Risiko         = $risk[$u.Name]
        _dep           = $dep
    }
}
$plan | Format-Table Konto, Admin, RDP, LetzteAnmeldung, PasswortGesetzt, Dienste, Aufgaben, Risiko -AutoSize -Wrap

Write-Host "Ausgenommen: $($Exclude -join ', ')" -ForegroundColor DarkGray
if (-not $Apply) {
    Write-Host "`nPROBELAUF - nichts geändert. Zum Ausführen: -Apply (optional -UpdateDependencies)." -ForegroundColor Yellow
    return
}

# --- Ausführen ---------------------------------------------------------------------------------
$answer = Read-Host "`n$($plan.Count) Passwörter jetzt ändern? (JA eingeben)"
if ($answer -cne 'JA') { Write-Host 'Abgebrochen.'; return }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outFile = Join-Path (Get-Location) "pw_rotation_${computer}_$stamp.csv"
New-Item -ItemType File -Path $outFile -Force | Out-Null
# Datei nur für den aktuellen Benutzer lesbar
# Nur Prozesskonto und angemeldetes Konto dürfen lesen
$grants = @("${computer}\${me}:(F)")
if ($interactive -and $interactive -ne $me) { $grants += "${computer}\${interactive}:(F)" }
icacls $outFile /inheritance:r /grant:r @grants | Out-Null

$results = foreach ($p in $plan) {
    $pw = New-StrongPassword $Length
    $secure = ConvertTo-SecureString $pw -AsPlainText -Force
    $status = 'OK'
    try {
        Set-LocalUser -Name $p.Konto -Password $secure
        if ($UpdateDependencies) {
            foreach ($s in $p._dep.Services) {
                $r = & sc.exe config "$($s.Name)" obj= "$($s.StartName)" password= "$pw"
                if ($LASTEXITCODE -ne 0) { $status = "Dienst $($s.Name): $r" }
            }
            foreach ($t in $p._dep.Tasks | Where-Object { $PSItem.Principal.LogonType -eq 'Password' }) {
                Set-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -User $t.Principal.UserId -Password $pw | Out-Null
            }
        }
    } catch { $status = "FEHLER: $($PSItem.Exception.Message)" }
    [pscustomobject]@{ Konto = $p.Konto; Passwort = $pw; Status = $status; Zeit = (Get-Date -Format s) }
}

$results | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
$results | Select-Object Konto, Status, Zeit | Format-Table -AutoSize

Write-Host "`nNeue Passwörter: $outFile" -ForegroundColor Green
Write-Host 'Jetzt in den Passwortmanager übernehmen, danach die Datei löschen (Remove-Item).' -ForegroundColor Yellow
Write-Host 'Bestehende RDP-Sitzungen bleiben angemeldet - Fremdsitzungen mit "logoff <ID>" beenden (nicht die JTL-Worker-Sitzung).' -ForegroundColor Yellow
