<#
.SYNOPSIS
  Rein lesende Sichtung eines Windows-Servers (JTL/ecomdata) für Forensik und Härtung.

.DESCRIPTION
  Schreibt Konten, Sitzungen, Dienste, geplante Aufgaben (mit Konto und Aktion), offene Ports mit Prozessen,
  Firewall-Regeln mit IP-Filtern, SQL-Instanzen und Datenbanken, installierte Software, Freigaben,
  OpenSSH, RDP-Einstellungen, Autologon und Ereignisprotokolle (Security, RDP, Application) in einen
  Ordner, packt ihn als ZIP und bildet SHA-256-Prüfsummen. Ändert nichts am System.

  Passwörter/Secrets werden nicht ausgelesen. Config-Dateien unter -CopyPaths werden 1:1 kopiert
  (können Zugangsdaten enthalten -> ZIP vertraulich behandeln).

.EXAMPLE
  .\sichtung_windows_server.ps1
.EXAMPLE
  .\sichtung_windows_server.ps1 -CopyPaths 'C:\Users\useradmin\Documents\jtl_db_reader'

  Meesenburg, 12.10.2026
#>
[CmdletBinding()]
param(
    [string]   $OutRoot = 'C:\tmp',
    [string[]] $CopyPaths = @(),
    [int]      $EventDays = 60
)
$ErrorActionPreference = 'Continue'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Bitte PowerShell als Administrator starten.' }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$dir = Join-Path $OutRoot "sichtung_$($env:COMPUTERNAME)_$stamp"
New-Item -ItemType Directory -Path $dir -Force | Out-Null
function Save($name, $obj) { $obj | Out-File -FilePath (Join-Path $dir $name) -Encoding utf8 -Width 400 }
function SaveCsv($name, $obj) { $obj | Export-Csv -Path (Join-Path $dir $name) -NoTypeInformation -Encoding UTF8 }
function Step($t) { Write-Host "- $t" -ForegroundColor Cyan }

Step 'System'
Save '00_system.txt' (Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsBuildNumber, OsLastBootUpTime, CsDomain, OsUptime | Format-List | Out-String)
Save '00_ipconfig.txt' (ipconfig /all)

Step 'Konten und Gruppen'
SaveCsv '10_lokale_konten.csv' (Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, PasswordExpires, Description)
$groups = foreach ($g in Get-LocalGroup) {
    foreach ($m in (Get-LocalGroupMember -Group $g.Name -ErrorAction SilentlyContinue)) {
        [pscustomobject]@{ Gruppe = $g.Name; Mitglied = $m.Name; Typ = $m.ObjectClass; Quelle = $m.PrincipalSource }
    }
}
SaveCsv '11_gruppenmitglieder.csv' $groups
Save '12_sitzungen.txt' (quser 2>&1)
Save '13_profile.txt' (Get-CimInstance Win32_UserProfile | Where-Object { -not $PSItem.Special } |
    Select-Object LocalPath, LastUseTime, Loaded | Format-Table -AutoSize | Out-String)
$wl = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Save '14_autologon.txt' ("AutoAdminLogon=$($wl.AutoAdminLogon) DefaultUserName=$($wl.DefaultUserName) DefaultPassword gesetzt=$([bool]$wl.DefaultPassword)")

Step 'Dienste und geplante Aufgaben'
SaveCsv '20_dienste.csv' (Get-CimInstance Win32_Service | Select-Object Name, DisplayName, State, StartMode, StartName, PathName)
$tasks = foreach ($t in Get-ScheduledTask) {
    [pscustomobject]@{
        Pfad = $t.TaskPath; Name = $t.TaskName; Status = $t.State
        Konto = $t.Principal.UserId; LogonTyp = $t.Principal.LogonType; RunLevel = $t.Principal.RunLevel
        Aktion = (($t.Actions | ForEach-Object { "$($PSItem.Execute) $($PSItem.Arguments)" }) -join ' | ')
        Trigger = (($t.Triggers | ForEach-Object { $PSItem.CimClass.CimClassName }) -join ', ')
        Autor = $t.Author
    }
}
SaveCsv '21_geplante_aufgaben.csv' $tasks
New-Item -ItemType Directory -Path (Join-Path $dir 'aufgaben_xml') | Out-Null
Get-ScheduledTask | Where-Object { $PSItem.TaskPath -notlike '\Microsoft\*' } | ForEach-Object {
    $safe = ($PSItem.TaskPath + $PSItem.TaskName) -replace '[\\/:*?"<>|]', '_'
    Export-ScheduledTask -TaskName $PSItem.TaskName -TaskPath $PSItem.TaskPath | Out-File (Join-Path $dir "aufgaben_xml\$safe.xml") -Encoding utf8
}
Save '22_autostart.txt' (Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User, Location | Format-Table -AutoSize | Out-String)

Step 'Netzwerk und Prozesse'
$procs = @{}; Get-Process -IncludeUserName -ErrorAction SilentlyContinue | ForEach-Object { $procs[$PSItem.Id] = $PSItem }
$listen = Get-NetTCPConnection -State Listen | ForEach-Object {
    $p = $procs[[int]$PSItem.OwningProcess]
    [pscustomobject]@{ Adresse = $PSItem.LocalAddress; Port = $PSItem.LocalPort; PID = $PSItem.OwningProcess
        Prozess = $p.ProcessName; Benutzer = $p.UserName; Pfad = $p.Path; Sitzung = $p.SessionId }
} | Sort-Object Port
SaveCsv '30_lauschende_ports.csv' $listen
SaveCsv '31_prozesse.csv' ($procs.Values | Select-Object Id, ProcessName, UserName, SessionId, StartTime, Path)
Save '32_verbindungen.txt' (Get-NetTCPConnection -State Established | Select-Object LocalPort, RemoteAddress, RemotePort, OwningProcess | Sort-Object RemoteAddress | Format-Table -AutoSize | Out-String)
Save '33_urlacl.txt' (netsh http show urlacl)

Step 'Firewall'
netsh advfirewall export (Join-Path $dir '40_firewall.wfw') | Out-Null
$fw = Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow | ForEach-Object {
    $pf = $PSItem | Get-NetFirewallPortFilter; $af = $PSItem | Get-NetFirewallAddressFilter
    $ra = @($af.RemoteAddress) -join ', '
    if ($ra -notmatch '^(Any|Beliebig)$' -or $pf.LocalPort -notmatch '^(Any|Beliebig)$') {
        [pscustomobject]@{ Name = $PSItem.DisplayName; Id = $PSItem.Name; Protokoll = $pf.Protocol
            Ports = (@($pf.LocalPort) -join ','); Remote = $ra }
    }
}
SaveCsv '41_firewall_regeln_mit_filter.csv' $fw

Step 'RDP und OpenSSH'
$rdp = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Save '50_rdp.txt' ("Port=$($rdp.PortNumber) NLA(UserAuthentication)=$($rdp.UserAuthentication) SecurityLayer=$($rdp.SecurityLayer) fDenyTSConnections=$((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections)")
if (Test-Path 'C:\ProgramData\ssh') {
    Copy-Item 'C:\ProgramData\ssh\sshd_config' (Join-Path $dir '51_sshd_config.txt') -ErrorAction SilentlyContinue
    Get-ChildItem 'C:\ProgramData\ssh' -Force | Select-Object Name, Length, LastWriteTime | Format-Table | Out-String | Out-File (Join-Path $dir '52_ssh_ordner.txt')
    if (Test-Path 'C:\ProgramData\ssh\administrators_authorized_keys') {
        Copy-Item 'C:\ProgramData\ssh\administrators_authorized_keys' (Join-Path $dir '53_administrators_authorized_keys.txt')
    }
    Get-ChildItem 'C:\Users\*\.ssh\authorized_keys' -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $PSItem.FullName (Join-Path $dir ("54_authorized_keys_" + $PSItem.Directory.Parent.Name + '.txt'))
    }
}

Step 'Software, Freigaben, Updates'
$sw = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $PSItem.DisplayName } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName
SaveCsv '60_software.csv' $sw
Save '61_freigaben.txt' (Get-SmbShare | Format-Table -AutoSize | Out-String)
Save '62_updates.txt' (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 15 | Format-Table -AutoSize | Out-String)
Save '63_laufwerke.txt' (Get-PSDrive -PSProvider FileSystem | Format-Table -AutoSize | Out-String)

Step 'SQL Server'
$inst = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction SilentlyContinue).PSObject.Properties |
    Where-Object { $PSItem.Name -notlike 'PS*' } | ForEach-Object { $PSItem.Name }
Save '70_sql_instanzen.txt' ($inst -join "`r`n")
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
foreach ($i in $inst) {
    $server = if ($i -eq 'MSSQLSERVER') { '.' } else { ".\$i" }
    $q = "SET NOCOUNT ON; SELECT d.name, d.create_date, d.state_desc, CAST(SUM(f.size)*8/1024 AS int) AS MB, (SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset b WHERE b.database_name=d.name) AS letzte_sicherung FROM sys.databases d JOIN sys.master_files f ON f.database_id=d.database_id GROUP BY d.name,d.create_date,d.state_desc ORDER BY d.name; SELECT name, type_desc, is_disabled, create_date, modify_date FROM sys.server_principals WHERE type IN ('S','U','G') ORDER BY modify_date DESC;"
    if ($sqlcmd) { Save "71_sql_$i.txt" (sqlcmd -S $server -E -W -s '|' -Q $q 2>&1) }
    else {
        try {
            $cn = New-Object System.Data.SqlClient.SqlConnection "Server=$server;Integrated Security=true;TrustServerCertificate=true"
            $cn.Open(); $cmd = $cn.CreateCommand(); $cmd.CommandText = $q
            $ds = New-Object System.Data.DataSet; (New-Object System.Data.SqlClient.SqlDataAdapter $cmd).Fill($ds) | Out-Null; $cn.Close()
            Save "71_sql_$i.txt" (($ds.Tables | ForEach-Object { $PSItem | Format-Table -AutoSize | Out-String }) -join "`r`n")
        } catch { Save "71_sql_$i.txt" "Fehler: $($PSItem.Exception.Message)" }
    }
}

Step "Ereignisprotokolle (letzte $EventDays Tage)"
$since = (Get-Date).AddDays(-$EventDays)
foreach ($log in 'Security', 'System', 'Application', 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational', 'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational', 'OpenSSH/Operational') {
    $file = Join-Path $dir ("80_" + ($log -replace '[\\/]', '_') + '.evtx')
    wevtutil epl $log $file "/q:*[System[TimeCreated[@SystemTime>='$($since.ToUniversalTime().ToString('o'))']]]" 2>$null
}
$logons = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624; StartTime = $since } -ErrorAction SilentlyContinue |
    Where-Object { $PSItem.Properties[8].Value -in 3, 10 } | ForEach-Object {
        [pscustomobject]@{ Zeit = $PSItem.TimeCreated; Konto = $PSItem.Properties[5].Value; Typ = $PSItem.Properties[8].Value; IP = $PSItem.Properties[18].Value }
    }
SaveCsv '81_anmeldungen_netzwerk_rdp.csv' $logons
Save '82_anmeldungen_je_konto_ip.txt' ($logons | Group-Object Konto, IP | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize | Out-String)

foreach ($p in $CopyPaths) {
    if (Test-Path $p) { Step "Kopiere $p"; Copy-Item $p (Join-Path $dir ('kopie_' + (Split-Path $p -Leaf))) -Recurse -ErrorAction SilentlyContinue }
}

Step 'Prüfsummen und ZIP'
# Erst alle Prüfsummen berechnen, dann schreiben (sonst sperrt sich die Datei selbst)
$hashes = @(Get-ChildItem $dir -Recurse -File | Get-FileHash -Algorithm SHA256 |
    Select-Object @{ n = 'Datei'; e = { $PSItem.Path.Substring($dir.Length + 1) } }, Hash)
$hashes | Export-Csv (Join-Path $dir '_sha256.csv') -NoTypeInformation -Encoding UTF8
$zip = "$dir.zip"
Compress-Archive -Path "$dir\*" -DestinationPath $zip -Force
$h = (Get-FileHash $zip -Algorithm SHA256).Hash
Write-Host "`nFertig: $zip" -ForegroundColor Green
Write-Host "SHA-256: $h" -ForegroundColor Green
Write-Host 'Vertraulich behandeln (kann Zugangsdaten und personenbezogene Daten enthalten).' -ForegroundColor Yellow
