# ops-tools

| Ordner/Datei | Zweck |
|---|---|
| `rider/es-run-configs-auf-src.sh` | Rider-Run-/Debug-Konfigurationen von Meesenburg.ES auf `src/` umstellen (18.11.2026). Nur bei geschlossenem Rider, legt eine Sicherung von `workspace.xml` an |
| `windows-ssh-deploy/README.md` | Anleitung: .NET-Dienste vom Mac per SSH (OpenSSH-MSI, `scp -O`) auf Windows-Server deployen, mit Stolpersteinen (18.11.2026) |
| `siseshop/seo_html_check.py` | Was ein Crawler ohne JavaScript sieht (Title, Canonical, Robots, H1, JSON-LD, Bilder, Links), Stichprobe der Sitemap auf Status/Canonical/noindex. Nur lesend, Standardbibliothek (18.11.2026, Prüfliste C. Feller) |
| `siseshop/feedback_liste.py` | Liste „Problemverfolgung“ im Teams-Kanal (Feedback-Knopf) per App-Zugang prüfen: Spalten und interne Namen; Geheimnis aus dem Key Vault (19.11.2026) |
| `siseshop/` | Skripte aus dem SiSe-Shop-Projekt: Windows-Server (Sichtung, Passwort-Rotation, Firewall, RDP), Sicherung node2/node3, `md2pdf.py` (Berichte → PDF), Workshop-/Inhaltsskripte |
| `siseshop/lokal-admin-recht.sh` | Lokale Shop-Entwicklung: gibt dem per `az login` angemeldeten Konto die Rolle „Shop-Administration“ in der lokalen Aspire-Mongo (`siseshop`). Nötig, seit der Admin auch lokal nur per Entra anmeldet (19.11.2026). |
