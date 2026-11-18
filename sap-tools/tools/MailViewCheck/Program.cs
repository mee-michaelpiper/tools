// Vergleich der Rechnungs-Mailadressen (26.10.2026): YDD_CUSTOMERS_V2 (wie die SAP-API: alle Felder) vs. nur Mailfelder
// vs. YDH_SD_MAILS (KNVK Abteilung Y001 → ADR6). Nur lesend, MEP. Ausgabe auf der Konsole nur Zähler/Längen;
// Kundendaten (Nummer + Adressen) nur als CSV in den Ordner aus Argument 1 (Scratchpad).
//   DYLD_LIBRARY_PATH=/usr/local/lib dotnet run -- <ausgabeordner>
using System.Data;
using System.Runtime.InteropServices;
using ERPConnect;
using ERPConnect.Utils;

NativeLibrary.SetDllImportResolver(typeof(R3Connection).Assembly, (name, _, _) =>
    name.Contains("sapnwrfc") ? NativeLibrary.Load(Path.Combine(AppContext.BaseDirectory, "libsapnwrfc.dylib")) : IntPtr.Zero);
LIC.SetLic(SapSecrets.License);
using var con = new R3Connection("172.20.22.52", 0, SapSecrets.Rfc.User, SapSecrets.Rfc.Password, "DE", SapSecrets.Rfc.Client) { UsesLoadBalancing = false };
con.Open();
var outDir = args.ElementAtOrDefault(0) ?? throw new ArgumentException("Ausgabeordner fehlt");

DataTable Read(string table, string where, params string[] fields)
{
    var t = new ReadTable(con) { TableName = table, WhereClause = where };
    foreach (var f in fields) t.AddField(f);
    t.SetCustomFunctionName("/SAPDS/RFC_READ_TABLE2");
    t.Run();
    return t.Result;
}
static string S(DataRow r, string c) => r.Table.Columns.Contains(c) ? (r[c]?.ToString() ?? "").Trim() : "";

var full = Read("YDD_CUSTOMERS_V2", "ORGANISATIONID = '298'");  // wie SelectCustomer… in der API
var narrow = Read("YDD_CUSTOMERS_V2", "ORGANISATIONID = '298'", "CUSTOMERID", "MAIL", "INVOICEMAIL", "CMMAIL");
var mails = Read("YDH_SD_MAILS", "", "KUNNR", "SMTP_ADDR", "PARTNER", "NAMEV", "PERSNUMBER");
Console.WriteLine($"V2 alle Felder: {full.Rows.Count} Zeilen, Spalten {full.Columns.Count}; V2 schmal: {narrow.Rows.Count}; YDH_SD_MAILS: {mails.Rows.Count}");

var fullBy = full.AsEnumerable().GroupBy(r => S(r, "CUSTOMERID")).ToDictionary(g => g.Key, g => g.ToList());
var narrowBy = narrow.AsEnumerable().GroupBy(r => S(r, "CUSTOMERID")).ToDictionary(g => g.Key, g => g.ToList());
var mailBy = mails.AsEnumerable().GroupBy(r => S(r, "KUNNR")).ToDictionary(g => g.Key, g => g.ToList());

Console.WriteLine($"Kunden V2: {fullBy.Count}, davon mehrere Zeilen (alle Felder): {fullBy.Count(k => k.Value.Count > 1)}, schmal: {narrowBy.Count(k => k.Value.Count > 1)}");
using var csv = new StreamWriter(Path.Combine(outDir, "mailvergleich.csv"));
csv.WriteLine("kunde;feld;v2_alle_felder;v2_nur_mail;ydh_sd_mails;ydh_anzahl;ydh_namen;befund");
var stats = new Dictionary<string, int>();
void Count(string k) => stats[k] = stats.GetValueOrDefault(k) + 1;
foreach (var (kunnr, nrows) in narrowBy)
{
    var fRows = fullBy.GetValueOrDefault(kunnr) ?? [];
    foreach (var field in new[] { "INVOICEMAIL", "MAIL", "CMMAIL" })
    {
        var n = nrows.Select(r => S(r, field)).Where(v => v.Length > 0).Distinct().ToList();
        var f = fRows.Select(r => S(r, field)).Where(v => v.Length > 0).Distinct().ToList();
        string befund;
        if (n.Count == 0 && f.Count == 0) { Count($"{field}: leer"); continue; }
        if (n.SequenceEqual(f)) befund = "gleich";
        else if (f.Count == n.Count && f.Zip(n).All(p => p.Second.StartsWith(p.First))) befund = "alle Felder gekürzt";
        else befund = "abweichend";
        Count($"{field}: alle Felder vs. nur Mail = {befund}");
        var ydh = mailBy.GetValueOrDefault(kunnr) ?? [];
        var ydhMails = ydh.Select(r => S(r, "SMTP_ADDR")).Where(v => v.Length > 0).Distinct().ToList();
        if (field == "INVOICEMAIL")
        {
            Count(ydhMails.Count == 0 ? "INVOICEMAIL: YDH ohne Adresse"
                : ydhMails.Count > 1 ? "INVOICEMAIL: YDH mehrere Adressen"
                : n.Count == 1 && n[0] == ydhMails[0] ? "INVOICEMAIL: V2 schmal = YDH"
                : n.Count == 1 && ydhMails[0].StartsWith(n[0]) ? "INVOICEMAIL: V2 schmal gekürzt ggü. YDH"
                : "INVOICEMAIL: V2 schmal ≠ YDH");
            if (n.Count > 1) Count("INVOICEMAIL: V2 mehrere Adressen je Kunde");
        }
        if (befund != "gleich" || field == "INVOICEMAIL")
            csv.WriteLine($"{kunnr};{field};{string.Join(" ", f)};{string.Join(" ", n)};{(field == "INVOICEMAIL" ? string.Join(" ", ydhMails) : "")};{ydh.Count};" +
                          $"{(field == "INVOICEMAIL" ? string.Join(" / ", ydh.Select(r => $"{S(r, "NAMEV")} {S(r, "PARTNER")}".Trim()).Distinct()) : "")};{befund}");
    }
}
foreach (var (k, v) in stats.OrderBy(k => k.Key)) Console.WriteLine($"  {k}: {v}");
// Längen der gekürzten Werte (alle Felder) – zeigt, ob an fester Zeilenposition abgeschnitten wird
var cutLengths = narrowBy.SelectMany(kv => (fullBy.GetValueOrDefault(kv.Key) ?? []).Select(r => S(r, "INVOICEMAIL").Length)).Where(l => l > 0).GroupBy(l => l).OrderByDescending(g => g.Count()).Take(8);
Console.WriteLine("Häufigste Längen INVOICEMAIL (alle Felder): " + string.Join(", ", cutLengths.Select(g => $"{g.Key}×{g.Count()}")));
var names = mails.AsEnumerable().Select(r => $"{S(r, "NAMEV")} {S(r, "PARTNER")}".Trim().ToLowerInvariant()).ToList();
File.WriteAllLines(Path.Combine(outDir, "ydh_namen.txt"), names.GroupBy(x => x).OrderByDescending(g => g.Count()).Select(g => $"{g.Count()};{g.Key}"));
Console.WriteLine($"Namen in YDH_SD_MAILS: {names.Distinct().Count()} verschiedene bei {names.Count} Zeilen; mit „rechnung“: {names.Count(n => n.Contains("rechnung"))}, leer: {names.Count(n => n.Length == 0)}");
