// Prüft den Portal-Vorschlag „Steuerzeile je Position aufteilen“ (AccountingTransferService.AnalyzeBalance + TransferCsv.ApplyEdits)
// an einer Übergabedatei: Befund → Vorschlag anwenden → erneut prüfen.   dotnet run test.cs <datei.csv>
#:project ../../../../Meesenburg.ES/Meesenburg.ES.API.SAPData
#:property PublishAot=false
using System.Reflection;
using Meesenburg.ES.API.SAPData.Models.AccountingTransfer;
using Meesenburg.ES.API.SAPData.Services.AccountingTransfer;

var rates = new Dictionary<string, (string ConditionType, decimal RatePerMille)> { ["V1"] = ("MWVS", 190m), ["A1"] = ("MWAS", 190m) };
var analyze = typeof(AccountingTransferService).GetMethod("AnalyzeBalance", BindingFlags.NonPublic | BindingFlags.Static)!;
var lines = TransferCsv.ReadLines(TransferCsv.Decode(File.ReadAllBytes(args[0])));

List<TransferFinding> Check(List<TransferLine> all, out List<TransferLine> doc)
{
    var header = all.First(TransferCsv.IsHeader);
    doc = all.SkipWhile(l => l != header).Skip(1).TakeWhile(TransferCsv.IsItem).ToList();
    var balance = doc.Sum(l => (TransferCsv.Amount(TransferCsv.Cell(l, TransferCsv.PAmount)) ?? 0m) * TransferCsv.Sign(TransferCsv.Cell(l, TransferCsv.PKey)));
    var findings = new List<TransferFinding>();
    analyze.Invoke(null, [header, doc, balance, (IReadOnlyDictionary<string, (string, decimal)>)rates, findings]);
    return findings;
}
var before = Check(lines, out _);
if (before.Count == 0) { Console.WriteLine("Keine Befunde – nichts aufzuteilen (z. B. MwSt auf die Summe gerechnet)"); return 0; }
foreach (var f in before) Console.WriteLine($"vorher: {f.Title} – {f.FixLabel ?? "kein Vorschlag"}\n   {f.Detail}");
var fix = before.FirstOrDefault(f => f.Fix is { Count: > 0 })?.Fix;
if (fix is null) { Console.WriteLine("FEHLER: kein Vorschlag"); return 1; }
foreach (var e in fix) Console.WriteLine($"   Änderung: Zeile {e.LineNumber}, Spalte {e.Column}: {e.Value}");
var after = TransferCsv.ApplyEdits(lines, fix);
var findingsAfter = Check(after, out var docAfter);
Console.WriteLine("nachher:"); foreach (var l in docAfter) Console.WriteLine("   " + string.Join(';', l.Cells));
Console.WriteLine(findingsAfter.Count == 0 ? "OK: keine Befunde mehr" : "FEHLER: " + string.Join(" | ", findingsAfter.Select(f => f.Title)));
return findingsAfter.Count == 0 ? 0 : 1;
