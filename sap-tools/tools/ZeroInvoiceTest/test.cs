// Prüft das Kriterium „0-€-Rechnung“ der Übergabe (AccountingService, 09.11.2026): Beleg ohne Positionen nach dem Mapping.
// Anlass: 900010658 (PRS, 0 €) kam als reine Kopfzeile in SAP_Export_20261105_183016.csv, SAP lehnte die ganze Datei ab.
//   dotnet run test.cs   (aus diesem Ordner)
#:project ../../../../Meesenburg.ES/ESDataWorker
#:property PublishAot=false
using Meesenburg.ES.DataWorker.Models.EsApi;

var fails = 0;
void Check(string name, int items, bool expectEmpty)
{
    var ok = (items == 0) == expectEmpty;
    if (!ok) fails++;
    Console.WriteLine($"{(ok ? "OK " : "FEHLER")} {name}: {items} Positionen");
}

InvoiceOut Out(decimal gross, params (decimal net, decimal vat)[] allocs) => new()
{
    InvoiceNumber = 900010658, InvoiceDate = new DateTime(2026, 11, 5), AccountNumber = 10080149, TotalGrossAmount = gross,
    TotalNetAmount = allocs.Sum(a => a.net),
    Allocations = allocs.Select(a => new InvoiceAlloc { NetAmount = a.net, VatAmount = a.vat, VatCode = "A1", VatRate = 19, OffsetAccount = 800000, CostCenter = 295 }).ToArray()
};
InvoiceIn In(decimal gross, params (decimal net, decimal vat)[] allocs) => new()
{
    SequentialInvoiceNumber = 910000001, InvoiceNumber = "R0", InvoiceDate = new DateTime(2026, 11, 5), AccountNumber = 95297,
    TotalGrossAmount = gross, TotalNetAmount = allocs.Sum(a => a.net), TotalVatAmount = allocs.Sum(a => a.vat),
    Allocations = allocs.Select(a => new InvoiceAlloc { NetAmount = a.net, VatAmount = a.vat, VatCode = "V1", VatRate = 19, OffsetAccount = 100205, CostCenter = 295 }).ToArray()
};

var outMapper = new InvoiceOutToSapMapper();
var inMapper = new InvoiceInToSapMapper();
Check("AR 0 € ohne Aufteilung", outMapper.MapToSapDocument(Out(-0m)).Items.Count, true);
Check("AR 0 € mit 0-Aufteilung", outMapper.MapToSapDocument(Out(0m, (0m, 0m))).Items.Count, true);
Check("AR 0 € mit +/- ausgeglichen", outMapper.MapToSapDocument(Out(0m, (100m, 19m), (-100m, -19m))).Items.Count, false);
Check("AR 119 €", outMapper.MapToSapDocument(Out(119m, (100m, 19m))).Items.Count, false);
Check("AR Gutschrift -119 €", outMapper.MapToSapDocument(Out(-119m, (-100m, -19m))).Items.Count, false);
Check("ER 0 € mit 0-Aufteilung", inMapper.MapToSapDocument(In(0m, (0m, 0m))).Items.Count, true);
Check("ER 119 €", inMapper.MapToSapDocument(In(119m, (100m, 19m))).Items.Count, false);

Console.WriteLine(fails == 0 ? "Alle Fälle OK" : $"{fails} Fehler");
return fails;
