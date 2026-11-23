# .NET-Dienste vom Mac per SSH auf Windows-Server deployen

Stand 18.11.2026, erstmals für den MeePasswordAnalyzerService auf VMMGMT002 eingerichtet.
Fertiges Beispiel: `~/repos/MeePasswordAnalyzerService/Scripts/deploy-from-mac.sh` und `Scripts/Update-Service.ps1`.

## Einmalig: Server vorbereiten (als Admin, per RDP)

1. **OpenSSH installieren.** `Add-WindowsCapability` scheitert bei uns mit `0x800f0954`, weil der Server über WSUS (`vmwsus001`) ohne Internet läuft.
   Deshalb das MSI von Microsoft nehmen (GitHub `PowerShell/Win32-OpenSSH` → Releases → `OpenSSH-Win64-v<Version>.msi`):
   ```powershell
   msiexec /i C:\Users\<admin>\Downloads\OpenSSH-Win64-v10.4.0.0.msi /qn ADDLOCAL=Server /l*v C:\Windows\Temp\openssh-install.log
   Set-Service sshd -StartupType Automatic; Start-Service sshd
   ```
2. **Firewall** auf die Admin- bzw. VPN-Netze beschränken:
   `Get-NetFirewallRule -DisplayName *OpenSSH* | Set-NetFirewallRule -RemoteAddress <Netz>`
3. **Schlüssel eintragen.** Für Konten aus der Gruppe der Administratoren gilt **nur** diese Datei, nicht `~\.ssh\authorized_keys`:
   ```powershell
   $f = 'C:\ProgramData\ssh\administrators_authorized_keys'
   Add-Content $f '<Inhalt der .pub-Datei>' -Encoding ascii
   icacls $f /inheritance:r /grant "*S-1-5-32-544:F" /grant "*S-1-5-18:F"   # nur Administratoren + SYSTEM, sonst ignoriert sshd die Datei
   ```
4. Optional: `New-ItemProperty HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -PropertyType String -Force`.
   Ohne diesen Eintrag ist die Shell `cmd`. Die Skripte rufen PowerShell deshalb immer ausdrücklich auf.

## Einmalig: Mac vorbereiten

```bash
ssh-keygen -t ed25519 -f ~/.ssh/meesenburg_mgmt -C "m.piper VMMGMT002"   # mit Passphrase
ssh-add --apple-use-keychain ~/.ssh/meesenburg_mgmt                       # Passphrase einmalig im Schlüsselbund
```
`~/.ssh/config`:
```
Host vmmgmt002
  HostName vmmgmt002.meesenburg.de
  User pipermi.admin
  IdentityFile ~/.ssh/meesenburg_mgmt
  IdentitiesOnly yes
  UseKeychain yes
  AddKeysToAgent yes
```
Test: `ssh vmmgmt002 hostname`

## Ablauf eines Deploys

0. **Darf jetzt deployt werden?** Beim Analyzer: `MeePasswordAnalyzerService.exe --print-status` auf dem Server (JSON-Zeile, Exit 0 frei,
   2 beschäftigt, 1 Fehler). Vorher prüfen, ob die installierte DLL den Schalter kennt
   (`Select-String -Path <dll> -Pattern '--print-status' -SimpleMatch -Encoding Unicode -Quiet`); eine alte exe würde sonst als zweite
   Instanz starten. Fertig umgesetzt in `deploy-from-mac.sh` (`STATUS_PS`).

1. **Bauen auf dem Mac:**
   `dotnet publish <proj>.csproj -c Release -r win-x64 --self-contained false -p:EnableWindowsTargeting=true -o <tmp>/publish`.
   Danach `appsettings*.json` und `*.pdb` löschen: Die Konfiguration des Servers bleibt dort, und sie enthält Zugangsdaten.
2. **Packen:** `COPYFILE_DISABLE=1 tar -czf build.tgz -C <tmp>/publish .`. `COPYFILE_DISABLE` verhindert macOS-Dateien `._*`.
3. **Hochladen:**
   ```bash
   ssh -n vmmgmt002 "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force C:\Temp\<Dienst>-Deploy\<Zeit>\build | Out-Null\""
   scp -O build.tgz Update-Service.ps1 vmmgmt002:C:/Temp/<Dienst>-Deploy/<Zeit>/
   ssh -n vmmgmt002 "tar -xzf C:\Temp\<Dienst>-Deploy\<Zeit>\build.tgz -C C:\Temp\<Dienst>-Deploy\<Zeit>\build"
   ```
4. **Einspielen:**
   `ssh -n vmmgmt002 "powershell -NoProfile -ExecutionPolicy Bypass -Command \"& 'C:\Temp\...\Update-Service.ps1' -SourcePath 'C:\Temp\...\build'\""`.
   Das Skript stoppt den Dienst, sichert nach `C:\Services\Backup\<Dienst>_<Zeit>`, kopiert per robocopy (ohne `appsettings*.json`,
   `*.pdb` und `logs`), startet den Dienst und gibt den Befehl für das Zurückspielen aus.
5. **Aufräumen:** den Staging-Ordner auf dem Server löschen, auch wenn ein Schritt fehlschlägt (`trap` im Skript).
6. **Prüfen:** Status des Dienstes und die letzten Zeilen des Logs, z. B.
   `ssh -n vmmgmt002 "powershell -NoProfile -Command \"Get-Content C:\Services\<Dienst>\logs\<datei>.log -Tail 20\""`

## Stolpersteine (alle am 18.11.2026 aufgetreten)

| Problem | Lösung |
|---|---|
| `scp: Connection closed` | Das SFTP-Subsystem des MSI v10.4 bricht ab. **`scp -O`** nutzt das klassische SCP-Protokoll und funktioniert |
| Eingaben an das Skript (z. B. `echo j \|`) kommen nicht an | `ssh` liest stdin mit, deshalb **`ssh -n`** für alle Fernbefehle |
| `.ps1` meldet „Unerwartetes Token“ bei `–` oder Umlauten | Windows PowerShell 5.1 liest UTF-8 **ohne BOM** als ANSI. `.ps1` als **UTF-8 mit BOM** speichern |
| `Permission denied (publickey)` | Schlüssel steht nicht in `administrators_authorized_keys`, oder die Datei hat falsche Rechte (`icacls` prüfen) |
| Umlaute im Log über ssh kaputt | Nur die Ausgabe auf der Konsole ist betroffen, die Datei ist in Ordnung. Bei Bedarf `Get-Content -Encoding UTF8` |
| PowerShell über ssh: Anführungszeichen, `\|` oder `$` gehen kaputt (cmd ist die Shell) | Skript als `-EncodedCommand` (UTF-16LE, Base64) schicken, siehe `remote_ps_enc` |
| Ausgabe beginnt mit `#< CLIXML` | Fortschrittsmeldungen von PowerShell: `$ProgressPreference='SilentlyContinue'` voranstellen |
| Versionsnummer alt und neu gleich | Die Version enthält den Git-Hash, ungecommittete Änderungen ändern ihn nicht. Zum Vergleich die Build-Zeit (`LastWriteTime` der DLL) heranziehen |

## Für DevTools übernehmen

Je Dienst anzugeben: Host-Alias, Projektdatei, Dienstname, Installationspfad (oder aus `Win32_Service.PathName` ermitteln), Vorabprüfung
(beim Analyzer: `--print-status`, Exit 2 = nicht deployen). Ein Probelauf (`--dry-run`) lädt hoch, zeigt Version und
Build-Zeit alt/neu und ändert am Dienst nichts.
