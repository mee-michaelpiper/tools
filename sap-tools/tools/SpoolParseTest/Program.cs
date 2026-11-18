// Test (11.11.2026): Spoolliste des Übergabe-Reports parsen (SAPBroker.ParseTransferSpool) und SapReferenceUse-Zustände.
// Eingabe: Ausgabe von `SapRead spool <Job> <Nr>` als Datei.
using Meesenburg.ES.API.SAPData.Brokers.ERP;
using Meesenburg.ES.API.SAPData.Models.AccountingTransfer;

var lines = File.ReadAllLines(args[0]).Select(l => l.StartsWith("   ") ? l[3..] : l);
var msgs = SAPBroker.ParseTransferSpool(lines);
var ok = 0; var fail = 0;
void Check(bool c, string what) { if (c) ok++; else { fail++; Console.WriteLine("FEHLER: " + what); } }
Console.WriteLine($"{msgs.Count} Meldungen");
Check(msgs.Count > 100, "mehr als 100 Zeilen");
var dup = msgs.Single(m => m.Reference == "910010148");
Check(dup.Type == "E" && dup.LineNumber == 98 && dup.Text.Contains("bereits unter Beleg 298,2026,0010070788"), "910010148 doppelt");
var rw = msgs.Where(m => m.Reference == "910010510").ToList();
Check(rw.Count == 2 && rw.All(m => m.Type == "E") && rw.Any(m => m.MessageId == "RW" && m.MessageNumber == "22"), "910010510 RW 022");
Check(msgs.Where(m => m.Type is "E" or "A").Select(m => m.Reference).Distinct().Count() == 2, "nur 2 fehlerhafte Belege");
Check(msgs.All(m => m.FileName == "SAP_Export_20261110_183011.csv"), "Dateiname");
Check(new SapReferenceUse("20261005", "0010070751", "2026", "0010070788", "").StateText == "Storno-Paar mit Beleg 10070788", "Storno-Text");
Check(!new SapReferenceUse("x", "1", "2026", "0010070788", "").IsPosted && new SapReferenceUse("x", "1", "2026", "", "").IsPosted && !new SapReferenceUse("x", "1", "2026", "", "Z").IsPosted, "IsPosted");
Console.WriteLine($"{ok} OK, {fail} Fehler");
return fail;
