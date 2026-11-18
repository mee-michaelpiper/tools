# JTL-Werkzeuge (nur lesend)

- `JtlSqlRead` – nur lesend: SQL gegen die JTL-Wawi (eazybusiness). `./run.sh "SELECT …"` baut den SSH-Tunnel über node1 (14330) und nimmt die Verbindung aus den User-Secrets des SiseShop-AppHost. Keine Kundendaten ausgeben. Vorkasse: `Verkauf.tAuftrag` (kZahlungsart 23) + `Verkauf.tAuftragEckdaten` (dBezahlt, fOffenerWert), Zahlungen in `tZahlung`.
