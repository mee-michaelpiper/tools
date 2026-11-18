# Pruefung vor dem Einrichten - aendert nichts. PowerShell "Als Administrator" auf c10330.
Get-ComputerInfo -Property OsName, OsVersion | Format-List | Out-Host
"--- OpenSSH-Server ---" | Out-Host
Get-WindowsCapability -Online -Name OpenSSH.Server* | Format-Table Name, State -AutoSize | Out-Host
Get-Service sshd -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize | Out-Host
"--- SQL-Server lauscht auf ---" | Out-Host
Get-NetTCPConnection -State Listen |
    Where-Object OwningProcess -in (Get-Process sqlservr -ErrorAction SilentlyContinue).Id |
    Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize | Out-Host
"--- Admin-Sitzung? ---" | Out-Host
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Out-Host
