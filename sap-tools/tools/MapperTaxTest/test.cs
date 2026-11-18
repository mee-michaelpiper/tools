// Prüft InvoiceInToSapMapper: Steuerzeile je Position nur bei MwSt-Rundung je Position (Freigabe Fibu 29.10.2026).
//   dotnet run test.cs   (aus diesem Ordner)
#:project ../../../../Meesenburg.ES/ESDataWorker
#:property PublishAot=false
using Meesenburg.ES.DataWorker.Models.EsApi;

var fails = 0;
void Case(string name, decimal gross, decimal vat, (decimal net, decimal vat)[] allocs, int expectedTaxLines)
{
    var inv = new InvoiceIn
    {
        SequentialInvoiceNumber = 1, InvoiceNumber = name, InvoiceDate = new DateTime(2026, 10, 20), AccountNumber = 95297,
        TotalGrossAmount = gross, TotalNetAmount = allocs.Sum(a => a.net), TotalVatAmount = vat,
        Allocations = allocs.Select(a => new InvoiceAlloc { NetAmount = a.net, VatAmount = a.vat, VatCode = "V1", VatRate = 19, OffsetAccount = 100205, CostCenter = 295 }).ToArray()
    };
    var doc = new InvoiceInToSapMapper().MapToSapDocument(inv);
    decimal Sign(string k) => k is "40" or "21" ? 1 : -1;
    var balance = doc.Items.Sum(i => i.BetragBelegwaehrungFW * Sign(i.Buchungsschluessel));
    var tax = doc.Items.Where(i => i.Konto == "154000").ToList();
    var ok = tax.Count == expectedTaxLines && balance == 0;
    if (!ok) fails++;
    Console.WriteLine($"{(ok ? "OK " : "FEHLER")} {name}: Saldo {balance}, Steuerzeilen {string.Join(" | ", tax.Select(t => $"{t.Buchungsschluessel} {t.BetragBelegwaehrungFW} auf {t.SteuerbasisbetragBelegwaehrung}"))}");
}
// 910010211: Lieferant je Position (4,40 → 0,84; 45,87 → 8,72 = 9,56; Summe 50,27 × 19 % = 9,55)
Case("910010211 je Position", 59.83m, 9.56m, [(4.40m, 0.84m), (45.87m, 8.72m)], 2);
// gleiche Rechnung, API verteilt die Kopf-MwSt anders auf die Aufteilungen
Case("910010211 andere Verteilung", 59.83m, 9.56m, [(4.40m, 0.83m), (45.87m, 8.73m)], 2);
// 910010321: B2B, MwSt auf die Summe (127,96 × 19 % = 24,31; je Position wären es 24,32)
Case("910010321 auf Summe", 152.27m, 24.31m, [(118.66m, 22.54m), (9.30m, 1.77m)], 1);
// normale Rechnung, beide Rechnungen gleich
Case("910010325 normal", 208.44m, 33.28m, [(138.89m, 26.39m), (26.40m, 5.02m), (9.87m, 1.87m)], 1);
// Gutschrift je Position
Case("Gutschrift je Position", -59.83m, -9.56m, [(-4.40m, -0.84m), (-45.87m, -8.72m)], 2);
// Rabattposition je Position: 100,03 → 19,01; 50,03 → 9,51; −10,03 → −1,91 = 26,61; Summe 140,03 × 19 % = 26,61 → gleich, also 1 Zeile
Case("Rabatt, gleich", 166.64m, 26.61m, [(100.03m, 19.01m), (50.03m, 9.51m), (-10.03m, -1.91m)], 1);
// Rabattposition, je Position verschieden: 4,40 → 0,84; 45,87 → 8,72; −0,90 → −0,17 = 9,39; Summe 49,37 × 19 % = 9,38
Case("Rabatt je Position", 58.76m, 9.39m, [(4.40m, 0.84m), (45.87m, 8.72m), (-0.90m, -0.17m)], 3);
// Datenfehler: MwSt passt zu keiner Rechnung → 1 Zeile, Fehler bleibt sichtbar (Saldo darf hier abweichen)
var before = fails; Case("Datenfehler", 59.87m, 9.60m, [(4.40m, 0.88m), (45.87m, 8.72m)], 1);
if (fails > before) { fails = before; Console.WriteLine("   (erwartet: Saldo ≠ 0 bleibt, nur 1 Steuerzeile)"); }
Console.WriteLine(fails == 0 ? "Alle Fälle wie erwartet" : $"{fails} Fälle falsch");
return fails;
