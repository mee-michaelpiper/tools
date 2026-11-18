// Test (13.11.2026): Lieferanten-Umwandlung im Worker – ein Lieferant mit Rechnungssteller W0100 (Lieferant 2, SAP-Änderung 12.11.)
// darf den Lauf nicht abbrechen; er landet in „failed“, die anderen werden umgewandelt.
using Meesenburg.ES.DataWorker.Models.EsApi;
using Sap = Meesenburg.ES.DataWorker.Models.SapApi;

Sap.Supplier Make(string id, string? biller) => new() { SupplierId = id, Biller = biller!, Name1 = "Test " + id };
var input = new List<Sap.Supplier> { Make("0000000002", "W0100"), Make("0000093131", ""), Make("0000096122", "0000000059") };
var failed = new List<(Sap.Supplier Supplier, Exception Error)>();
var result = input.ToEsSupplier(failed);
var fail = 0;
void Check(bool ok, string text) { Console.WriteLine((ok ? "OK     " : "FEHLER ") + text); if (!ok) fail++; }
Check(result.Count == 2, $"2 umgewandelt (ist {result.Count})");
Check(failed.Count == 1 && failed[0].Supplier.SupplierId == "0000000002", "Lieferant 2 übersprungen");
Console.WriteLine("       Grund: " + failed.FirstOrDefault().Error?.Message);
Check(result.Any(s => s.LieferantNr == 93131 && s.Kontonr == 93131), "ohne Rechnungssteller: Kontonr = Lieferant");
Check(result.Any(s => s.LieferantNr == 96122 && s.Kontonr == 59), "numerischer Rechnungssteller: Kontonr = 59");
Console.WriteLine(fail == 0 ? "alle OK" : $"{fail} Fehler");
return fail;
