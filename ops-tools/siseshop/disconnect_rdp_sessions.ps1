<#
.SYNOPSIS
  Trennt alle RDP-Sitzungen auf dem JTL-Server außer der eigenen, damit beim Wiederverbinden
  das (neue) Passwort abgefragt wird.

.DESCRIPTION
  Standard: Probelauf (zeigt nur an). -Apply trennt die Sitzungen (tsdiscon): Programme laufen weiter,
  der JTL-Worker in der useradmin-Sitzung bleibt aktiv, beim Wiederverbinden wird das Passwort abgefragt.
  -Logoff meldet stattdessen ab (beendet alle Programme der Sitzung) - useradmin ist davon immer
  ausgenommen und wird nur getrennt.

  Erst NACH dem Passwort-Rollieren ausführen (rotate_local_passwords.ps1), sonst geht es mit dem
  alten Passwort wieder hinein.

.EXAMPLE
  .\disconnect_rdp_sessions.ps1
.EXAMPLE
  .\disconnect_rdp_sessions.ps1 -Apply

  Meesenburg, 12.10.2026 - Bericht 12, Abschnitt 3.2
#>
[CmdletBinding()]
param(
    [switch] $Apply,
    [switch] $Logoff,
    # Sitzungen dieser Konten werden nicht angefasst (zusätzlich zur eigenen Sitzung)
    [string[]] $Keep = @()
)
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Bitte PowerShell als Administrator starten.' }

$mySession = (Get-Process -Id $PID).SessionId
# Konten, deren Sitzung nie abgemeldet wird (JTL-Worker), sondern höchstens getrennt
$neverLogoff = 'useradmin'

# quser-Ausgabe (auch deutsch) in Objekte zerlegen; aktive Zeile beginnt mit ">"
$sessions = @()
$lines = @(quser 2>$null) | Select-Object -Skip 1
foreach ($line in $lines) {
    $l = $line.TrimStart('>', ' ')
    $m = [regex]::Match($l, '^(?<user>\S+)\s+(?:(?<name>\S+)\s+)?(?<id>\d+)\s+(?<state>\S+)')
    if ($m.Success) {
        $sessions += [pscustomobject]@{
            Benutzer = $m.Groups['user'].Value
            Sitzung  = $m.Groups['name'].Value
            Id       = [int]$m.Groups['id'].Value
            Status   = $m.Groups['state'].Value
            Eigene   = ([int]$m.Groups['id'].Value -eq $mySession)
        }
    }
}

Write-Host "`n=== Sitzungen (eigene Sitzung: $mySession) ===" -ForegroundColor Cyan
$sessions | Format-Table -AutoSize

$targets = $sessions | Where-Object { -not $PSItem.Eigene -and $Keep -notcontains $PSItem.Benutzer }
$plan = foreach ($t in $targets) {
    $action = if ($Logoff -and $neverLogoff -notcontains $t.Benutzer) { 'abmelden' }
              elseif ($t.Status -match '^(Getr|Disc)') { 'bereits getrennt' }
              else { 'trennen' }
    [pscustomobject]@{ Benutzer = $t.Benutzer; Id = $t.Id; Status = $t.Status; Aktion = $action }
}
Write-Host '=== Geplant ===' -ForegroundColor Cyan
$plan | Format-Table -AutoSize

if (-not $Apply) {
    Write-Host 'PROBELAUF - nichts geändert. Zum Ausführen: -Apply (optional -Logoff).' -ForegroundColor Yellow
    return
}
$answer = Read-Host "Sitzungen jetzt $(if ($Logoff) { 'abmelden/trennen' } else { 'trennen' })? (JA eingeben)"
if ($answer -cne 'JA') { Write-Host 'Abgebrochen.'; return }

foreach ($p in $plan) {
    switch ($p.Aktion) {
        'abmelden' { logoff $p.Id; Write-Host "abgemeldet: $($p.Benutzer) ($($p.Id))" }
        'trennen'  { tsdiscon $p.Id; Write-Host "getrennt:   $($p.Benutzer) ($($p.Id))" }
        default    { Write-Host "unverändert: $($p.Benutzer) ($($p.Id)) - $($p.Aktion)" }
    }
}
Start-Sleep -Seconds 2
Write-Host "`n=== Danach ===" -ForegroundColor Cyan
quser
