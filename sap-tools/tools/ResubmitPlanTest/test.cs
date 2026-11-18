// Prüft „Erneut versuchen“ im Rechnungsversand (InvoiceResubmitter.Plan + Portal-Regel), u. a. Mailversand gescheitert (30.10.2026, 900010475).
//   dotnet run test.cs   (aus diesem Ordner) – schreibt nichts auf die Drehscheibe
#:project ../../../../Meesenburg.ES/Meesenburg.ES.ApiService
#:project ../../../../Meesenburg.ES/Meesenburg.ES.Web
#:property PublishAot=false
using System.Reflection;
using Meesenburg.ES.Jobs.Contracts.Api;

var plan = typeof(Meesenburg.ES.ApiService.Services.InvoiceResubmitter).GetMethod("Plan", BindingFlags.NonPublic | BindingFlags.Static)!;
var fails = 0;
void Case(string name, InvoiceDispatchDto inv, string? expectedFolder, string? expectedLabel)
{
    var p = plan.Invoke(null, [inv]);
    var folder = p?.GetType().GetProperty("FailedFolder")!.GetValue(p) as string;
    var files = p?.GetType().GetProperty("Files")!.GetValue(p) as System.Collections.IEnumerable;
    var label = Meesenburg.ES.Web.Services.InvoiceDispatchUi.ResubmitLabel(inv);
    var ok = (expectedFolder is null ? folder is null : folder?.EndsWith(expectedFolder) == true) && label == expectedLabel;
    if (!ok) fails++;
    Console.WriteLine($"{(ok ? "OK  " : "FAIL")} {name}: Plan={folder ?? "–"} Dateien={string.Join(", ", files?.Cast<object>().Select(f => f.ToString()) ?? [])} Knopf={label ?? "–"}");
}
InvoiceDispatchDto Inv(InvoiceChannel ch, InvoiceDispatchStatus st, string folder, params string[] codes) => new()
{
    Id = $"{ch}:900010475", InvoiceNo = "900010475", Channel = ch, Status = st,
    Events = [new() { AtUtc = new DateTime(2026, 10, 29, 10, 46, 39, DateTimeKind.Utc), Folder = folder, File = "Rechnung 900010475.pdf", Status = InvoiceDispatchStatus.Failed }],
    Findings = [.. codes.Select(c => new InvoiceDispatchFinding { Code = c, IsError = c != "VD-Valitool-71" })]
};
Case("900010475 Mailversand gescheitert", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Versand_fehlerhaft", "MAILVERSAND_FEHLGESCHLAGEN", "VD-Valitool-71"), @"ZUGFeRD_ES2000\Versand_fehlerhaft", "Erneut versuchen");
Case("Stand heute in Mongo (ohne neuen Befund)", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Versand_fehlerhaft", "VD-Valitool-71"), null, null);
Case("XRechnung Mailversand gescheitert", Inv(InvoiceChannel.XRechnung, InvoiceDispatchStatus.Failed, "Versand_fehlerhaft", "MAILVERSAND_FEHLGESCHLAGEN"), @"XRechnung_ES2000\Versand_fehlerhaft", "Erneut versuchen");
Case("Valitool nicht gelaufen (wie bisher)", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Konvertierung_fehlerhaft", "VALITOOL_NICHT_GELAUFEN"), @"ZUGFeRD_ES2000\Konvertierung_fehlerhaft", "Erneut versuchen");
Case("900010695 Abbruch nach Prüfung (esERP-Abfrage, 09.11.2026)", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Konvertierung_fehlerhaft", "ABBRUCH_NACH_PRUEFUNG", "VD-Valitool-71"), @"ZUGFeRD_ES2000\Konvertierung_fehlerhaft", "Erneut versuchen");
Case("XRechnung Abbruch nach Prüfung", Inv(InvoiceChannel.XRechnung, InvoiceDispatchStatus.Failed, "Konvertierung_fehlerhaft", "ABBRUCH_NACH_PRUEFUNG"), @"XRechnung_ES2000\Konvertierung_fehlerhaft", "Erneut versuchen");
Case("Abbruch nach Prüfung, Datei aber in Versand_fehlerhaft", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Versand_fehlerhaft", "ABBRUCH_NACH_PRUEFUNG"), null, null);
Case("Befund passt nicht zum Ordner", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Konvertierung_fehlerhaft", "MAILVERSAND_FEHLGESCHLAGEN"), null, null);
Case("Echter Datenfehler (Exit 24)", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Failed, "Konvertierung_fehlerhaft", "BR-CO-15"), null, null);
Case("Schon versendet", Inv(InvoiceChannel.ZUGFeRD, InvoiceDispatchStatus.Sent, "Versand_fehlerhaft", "MAILVERSAND_FEHLGESCHLAGEN"), null, null);
Console.WriteLine(fails == 0 ? "Alle Fälle OK" : $"{fails} Fehler");
return fails;
