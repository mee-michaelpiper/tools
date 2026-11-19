# JTL-Werkzeuge (nur lesend)

- `JtlSqlRead` – nur lesend: SQL gegen die JTL-Wawi (eazybusiness). `./run.sh "SELECT …"` baut den SSH-Tunnel über node1 (14330) und nimmt die Verbindung aus den User-Secrets des SiseShop-AppHost. Keine Kundendaten ausgeben. Vorkasse: `Verkauf.tAuftrag` (kZahlungsart 23) + `Verkauf.tAuftragEckdaten` (dBezahlt, fOffenerWert), Zahlungen in `tZahlung`.
- `siseshop/jtl-ssh/` – OpenSSH auf den ecomdata-Windows-Servern, nur von node1 (Port 50022, nur Schlüssel): `00_pruefen.ps1` (ändert nichts), `01_openssh_einrichten.ps1` (c10330: Admin + Tunnel-Benutzer für SQL), `02_c22910_admin_ssh.ps1` (Testserver c22910: nur Admin `mpiper`, sichert vorher die Firewall). Mac: `ssh jtl` bzw. `ssh jtl-test`. Übergang bis node1–3 gekündigt sind (TODO in `sise-docs/shop/TODO.md`).
