<#
.SYNOPSIS
  Beschränkt die Windows-Firewall-Freigaben der JTL-Schnittstellen auf den Shop-Server node1.

.DESCRIPTION
  Probelauf (Standard): zeigt alle aktiven eingehenden Regeln für die angegebenen Ports mit ihren
  Remote-Adressen. Mit -Apply werden die Remote-Adressen dieser Regeln auf -Allow gesetzt
  (Standard: nur node1 = 136.243.107.86). Vorher wird die komplette Firewall exportiert (netsh).

  Betrifft nur die Windows-Firewall auf dem Server. Die Freigaben im ecomdata-Kundenportal
  (u. a. RDP) separat bereinigen - dort die eigenen Meesenburg-IPs NICHT entfernen.

.EXAMPLE
  .\restrict_jtl_firewall.ps1
.EXAMPLE
  .\restrict_jtl_firewall.ps1 -Apply

  Meesenburg, 12.10.2026 - Bericht 12, Abschnitt 3.2
#>
[CmdletBinding()]
param(
    [int[]]    $Ports = @(50443, 58080),
    [string[]] $Allow = @('136.243.107.86'),
    [switch]   $Apply
)
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Bitte PowerShell als Administrator starten.' }

function Get-PortRules {
    Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow | ForEach-Object {
        $rule = $PSItem
        $pf = $rule | Get-NetFirewallPortFilter
        $af = $rule | Get-NetFirewallAddressFilter
        $local = @($pf.LocalPort) | ForEach-Object { "$PSItem" }
        $hit = $Ports | Where-Object { $local -contains "$PSItem" }
        if ($hit) {
            [pscustomobject]@{
                Name        = $rule.Name
                DisplayName = $rule.DisplayName
                Ports       = ($local -join ',')
                Protokoll   = $pf.Protocol
                Remote      = (@($af.RemoteAddress) -join ', ')
                _rule       = $rule
            }
        }
    }
}

Write-Host "`n=== Aktive eingehende Regeln für Port(s) $($Ports -join ', ') ===" -ForegroundColor Cyan
$rules = @(Get-PortRules)
if (-not $rules) { Write-Warning 'Keine passende Regel gefunden.'; return }
$rules | Format-List DisplayName, Name, Ports, Protokoll, Remote

$open = $rules | Where-Object { $PSItem.Remote -match '^(Any|Beliebig)$' }
if ($open) { Write-Warning ("Regel(n) ohne IP-Beschränkung (Any): " + ($open.DisplayName -join ', ') + ' - werden mit -Apply ebenfalls auf -Allow beschränkt.') }

Write-Host "Ziel: Remote-Adressen = $($Allow -join ', ')" -ForegroundColor DarkGray
if (-not $Apply) {
    Write-Host "`nPROBELAUF - nichts geändert. Zum Ausführen: -Apply" -ForegroundColor Yellow
    return
}

$answer = Read-Host "`n$($rules.Count) Regel(n) auf $($Allow -join ', ') beschränken? (JA eingeben)"
if ($answer -cne 'JA') { Write-Host 'Abgebrochen.'; return }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$export = Join-Path (Get-Location) "firewall_vorher_$stamp.wfw"
netsh advfirewall export "$export" | Out-Null
Write-Host "Export vorher: $export" -ForegroundColor DarkGray

foreach ($r in $rules) {
    $r._rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $Allow
}

Write-Host "`n=== Danach ===" -ForegroundColor Cyan
Get-PortRules | Format-Table DisplayName, Ports, Remote -AutoSize -Wrap
Write-Host 'Rücknahme: netsh advfirewall import "<Exportdatei>"' -ForegroundColor DarkGray
Write-Host 'Test von node1:  curl -s -o /dev/null -w "%{http_code}" http://c10330.servers.ecomdata.de:50443/' -ForegroundColor DarkGray
