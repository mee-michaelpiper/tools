/*
  Lese-Login für das Shop-Backend – BETRIEB (vor dem Livegang ausführen, ersetzt die Entwicklungsrechte aus 01)
  -------------------------------------------------------------------------------
  Prinzip: KEIN db_datareader (Kunden-, Adress- und Auftragsdaten), sondern SELECT nur auf die Tabellen,
           die der Shop wirklich abfragt: src/Meesenburg.SiseShop.Core/Brokers/Erp/Jtl/Sql/JtlSqlQueries.cs.
           Liste vor Ausführung mit JtlSqlQueries abgleichen.
  Für den Betrieb zusätzlich: neues Passwort (Entwicklungs-Passwort gilt als bekannt), Zugang nur übers VPN.
*/

USE [eazybusiness];
ALTER ROLE [db_datareader] DROP MEMBER [siseshop_reader];
REVOKE VIEW DEFINITION TO [siseshop_reader];

GRANT SELECT ON [dbo].[teigenschaftwert]  TO [siseshop_reader];   -- Variationsaufpreise (J-15)
GRANT SELECT ON [dbo].[tKategorieRabatt]  TO [siseshop_reader];   -- Kategorie-Rabatte (E-N)
GRANT SELECT ON [dbo].[tversandart]       TO [siseshop_reader];   -- Versandpreise/Freigrenzen (J-13, E-H)
-- Wawi-Stand der Bestellungen (L3, J-40): Storno/komplett geliefert, Lieferscheine, Sendungsnummern
GRANT SELECT ON [Verkauf].[tAuftrag]      TO [siseshop_reader];   -- Hinweis: enthält Auftragsdaten; enger wäre eine Sicht nur mit kAuftrag, nStorno, nKomplettAusgeliefert
GRANT SELECT ON [dbo].[tLieferschein]     TO [siseshop_reader];
GRANT SELECT ON [dbo].[tVersand]          TO [siseshop_reader];
GRANT SELECT ON [dbo].[tShopKundenGruppe]          TO [siseshop_reader];   -- Standard-Kundengruppe des Shops (Gäste, Plan 5a P1)
GRANT SELECT ON [dbo].[tArtikelSichtbarkeit]       TO [siseshop_reader];   -- Sichtbarkeit je Kundengruppe (P2)
GRANT SELECT ON [dbo].[tKategorieSichtbarkeit]     TO [siseshop_reader];
GRANT SELECT ON [dbo].[tEigenschaftWertSichtbarkeit] TO [siseshop_reader];
GRANT SELECT ON [dbo].[tEigenschaftWertAufpreis]   TO [siseshop_reader];   -- Aufpreise je Kundengruppe (P6)
GRANT SELECT ON [dbo].[tArtikelSonderpreis]        TO [siseshop_reader];   -- Sonderpreise (P4)
GRANT SELECT ON [dbo].[tSonderpreise]              TO [siseshop_reader];
GRANT SELECT ON [dbo].[tPreis]                     TO [siseshop_reader];   -- Staffelpreise (P5)
GRANT SELECT ON [dbo].[tPreisDetail]               TO [siseshop_reader];
GRANT SELECT ON [dbo].[tArtikel]                   TO [siseshop_reader];   -- Grundpreis-Angaben (P7, nur Inhalt/Bezugsmenge gelesen)
GRANT SELECT ON [dbo].[tMassEinheit]               TO [siseshop_reader];
GRANT SELECT ON [dbo].[tlagerbestand]              TO [siseshop_reader];   -- Verfügbarkeit (P8)
GRANT SELECT ON [dbo].[tArtikelAttribut]           TO [siseshop_reader];   -- Gratisgeschenk ab (P10)
GRANT SELECT ON [dbo].[tAttributSprache]           TO [siseshop_reader];
GRANT SELECT ON [dbo].[tArtikelAttributSprache]    TO [siseshop_reader];
GRANT SELECT ON [dbo].[tkonfiggruppe]              TO [siseshop_reader];   -- Kleiner Konfigurator (S9a, Bericht 18 A)
GRANT SELECT ON [dbo].[tkonfiggruppesprache]       TO [siseshop_reader];
GRANT SELECT ON [dbo].[tkonfigshop]                TO [siseshop_reader];
GRANT SELECT ON [dbo].[tartikelkonfiggruppe]       TO [siseshop_reader];
GRANT SELECT ON [dbo].[tkonfigitem]                TO [siseshop_reader];
GRANT SELECT ON [dbo].[tkonfigitemsprache]         TO [siseshop_reader];
GRANT SELECT ON [dbo].[tkonfigitempreis]           TO [siseshop_reader];
GRANT SELECT ON [dbo].[tArtikelShop]               TO [siseshop_reader];   -- Position nur, wenn ihr Artikel im Shop aktiv ist

-- DENY aus 01 bleibt bestehen

USE [master];
ALTER LOGIN [siseshop_reader] WITH PASSWORD = N'$(ReaderPassword)';
