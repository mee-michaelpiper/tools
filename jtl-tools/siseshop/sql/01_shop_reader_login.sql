/*
  Lese-Login für das neue Shop-Backend – ENTWICKLUNGSZEIT (Bericht 14, Plan E-O; Bericht 13 J-19)
  -------------------------------------------------------------------------------
  Zweck:   Während der Entwicklung alle Tabellen der Wawi lesen können, um fehlende Daten
           (Aufpreise, Rabatte, Versandkosten, Bestand …) zu finden, ohne jedes Mal neue Rechte zu brauchen.
  Achtung: db_datareader öffnet auch Kunden-, Adress- und Auftragsdaten (DSGVO).
           Deshalb: nur über den SSH-Tunnel (tools/jtl-ssh), Passwort nur im Key Vault,
           keine Kundendaten in Repo, Logs, Tests oder Fixtures übernehmen.
           Vor dem Livegang auf 02_shop_reader_betrieb.sql umstellen (TODO).
  Ausführen: Admin auf dem JTL-Server (SQL-Instanz der Wawi, z. B. per SSMS oder sqlcmd), nach Freigabe.
  Passwort:  neu erzeugen (≥ 32 Zeichen, ohne Apostroph), nur im Key Vault ablegen (Secret "SiseShop-Dev", Feld Jtl.SqlConnectionString).
             Kommt als sqlcmd-Variable $(ReaderPassword) aus der Umgebung, steht also nie in der Datei:
             $env:ReaderPassword = '…'; sqlcmd -S localhost,50000 -E -b -i 01_shop_reader_login.sql; Remove-Item Env:ReaderPassword
  Rücknahme: siehe Ende der Datei.
*/

USE [master];
CREATE LOGIN [siseshop_reader] WITH PASSWORD = N'$(ReaderPassword)',
    CHECK_POLICY = ON, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [eazybusiness];

USE [eazybusiness];
CREATE USER [siseshop_reader] FOR LOGIN [siseshop_reader];

-- Alle Tabellen und Sichten lesen + Schema (Spalten, Sichten, Prozedur-Texte) einsehen
ALTER ROLE [db_datareader] ADD MEMBER [siseshop_reader];
GRANT VIEW DEFINITION TO [siseshop_reader];

-- Schreiben, Ausführen und Ändern bleibt verweigert – auch wenn später jemand eine Rolle zuweist
DENY INSERT, UPDATE, DELETE, EXECUTE, ALTER ON SCHEMA::[dbo] TO [siseshop_reader];

-- Prüfen
SELECT r.name AS rolle FROM sys.database_role_members m
JOIN sys.database_principals r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals u ON u.principal_id = m.member_principal_id
WHERE u.name = N'siseshop_reader';

/* Rücknahme komplett:
USE [eazybusiness]; DROP USER [siseshop_reader];
USE [master];       DROP LOGIN [siseshop_reader];
*/
