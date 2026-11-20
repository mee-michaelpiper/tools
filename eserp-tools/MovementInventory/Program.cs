// Bestandsaufnahme der Materialbewegungen (20.11.2026, Bewegungsbuch): Welche Bewegung aus esERP ist in SAP gebucht, welche steckt nur
// in einer Übergabedatei, welche wurde nie übergeben? Anlass: esERP filtert /lager/bewegungen nur nach Datum, Läufe außer der Reihe
// verloren dadurch Bewegungen (19.11.: 52). Analyse: sise-docs/es/ANALYSE_Buchhaltungsuebergabe_2026-11-19_Materialbewegungen.md
//
// Quellen (alle nur lesend): esERP-API /lager/bewegungen tageweise (Key Vault c4vApiCredentials-prod), alle CSV-Dateien der Freigabe
// (EsErpSmbCredentials), SAP-BKPF Belegart 67 mit Referenz „ES-<Nr>“ (über ~/repos/tools/sap-tools/SapRead). Ob eine Bewegung überhaupt
// an SAP geht, entscheidet derselbe AccountingMatToSapMapper wie im Worker.
//
// Aufruf: dotnet run -- [--from 2026-09-01] [--write]
//   ohne --write: nur Bericht (Konsole + out/bewegungen_<Datum>.csv, bleibt lokal – enthält Lager-/Kundenbezeichnungen)
//   mit  --write: zusätzlich das Bewegungsbuch Prod-ES-Worker/Accounting-Movements befüllen (Upsert je Bewegungsnummer)
using System.Diagnostics;
using System.Globalization;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Meesenburg.ES.DataWorker.Models.EsApi;
using MongoDB.Bson;
using MongoDB.Driver;
using SMBLibrary;
using SMBLibrary.Client;

var from = DateOnly.Parse(args.SkipWhile(a => a != "--from").Skip(1).FirstOrDefault() ?? "2026-09-01", CultureInfo.InvariantCulture);
var write = args.Contains("--write");
var today = DateOnly.FromDateTime(DateTime.Now);
var kv = new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential());

// ---------------------------------------------------------------- 1. esERP: alle Bewegungen, wochenweise (Datum inklusive)
var c4v = JsonDocument.Parse((await kv.GetSecretAsync("c4vApiCredentials-prod")).Value.Value).RootElement;
var http = new HttpClient { BaseAddress = new Uri("https://esapi.meesenburg.de"), Timeout = TimeSpan.FromMinutes(10) };
var login = await http.PostAsJsonAsync("/login", new { username = c4v.GetProperty("username").GetString(), token = c4v.GetProperty("token").GetString() });
login.EnsureSuccessStatusCode();
http.DefaultRequestHeaders.Authorization = new("Bearer", JsonDocument.Parse(await login.Content.ReadAsStringAsync()).RootElement.GetProperty("token").GetString());
var movements = new Dictionary<int, AccountingMat>();
for (var d = from; d <= today; d = d.AddDays(7))
{
    var end = d.AddDays(6) < today ? d.AddDays(6) : today;
    // Die API wertet nur das Datum: von = Tagesanfang (00:00), bis = ganzer Tag inklusive
    var json = await http.GetStringAsync($"/lager/bewegungen?datumVon={d:yyyy-MM-dd}T00:00:00&datumBis={end:yyyy-MM-dd}T00:00:00&pageNumber=1&pageSize=500000");
    var root = JsonDocument.Parse(json).RootElement;
    var items = root.ValueKind == JsonValueKind.Array ? root : root.GetProperty("items");
    foreach (var m in items.Deserialize<List<AccountingMat>>()!) movements.TryAdd(m.MovementNumber, m);
    Console.Error.Write($"\resERP {d:dd.MM.}–{end:dd.MM.}: {movements.Count} Bewegungen");
}
Console.Error.WriteLine();
var mapper = new AccountingMatToSapMapper();
var relevant = movements.Values.Where(m => mapper.MapToSapDocument(m) is not null).ToDictionary(m => m.MovementNumber);

// ---------------------------------------------------------------- 2. Freigabe: alle CSV-Dateien
var files = new Dictionary<int, List<string>>(); // Bewegung → Dateien (Ordner/Name)
var smb = JsonDocument.Parse((await kv.GetSecretAsync("EsErpSmbCredentials")).Value.Value).RootElement;
string S(string n) => smb.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(S("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("SMB: keine Verbindung");
if (client.Login(S("Domain"), S("Username"), S("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("SMB: Anmeldung fehlgeschlagen");
var store = client.TreeConnect(S("Share"), out _);
const string Root = @"Daten\Programme\SAP\MEP\ES_ERP\Rechnungen";
var csvCount = 0;
void Walk(string dir)
{
    if (store.CreateFile(out var h, out _, dir, AccessMask.GENERIC_READ, SMBLibrary.FileAttributes.Directory, ShareAccess.Read | ShareAccess.Write,
            CreateDisposition.FILE_OPEN, CreateOptions.FILE_DIRECTORY_FILE, null) != NTStatus.STATUS_SUCCESS) return;
    store.QueryDirectory(out var entries, h, "*", FileInformationClass.FileDirectoryInformation);
    store.CloseFile(h);
    foreach (var e in entries.Cast<FileDirectoryInformation>().Where(e => e.FileName is not "." and not ".."))
    {
        var path = dir + "\\" + e.FileName;
        if (e.FileAttributes.HasFlag(SMBLibrary.FileAttributes.Directory)) { if (e.FileName != "FIS") Walk(path); continue; }
        if (!e.FileName.EndsWith(".csv", StringComparison.OrdinalIgnoreCase)) continue;
        csvCount++;
        var text = Encoding.UTF8.GetString(Read(path));
        var label = path[(Root.Length + 1)..];
        foreach (var line in text.Split('\n'))
        {
            var cells = line.Split(';');
            if (cells.Length > 7 && cells[0] == "K" && cells[7].StartsWith("ES-") && int.TryParse(cells[7][3..].Trim(), out var nr))
                (files.TryGetValue(nr, out var l) ? l : files[nr] = []).Add(label);
        }
    }
}
byte[] Read(string path)
{
    store.CreateFile(out var h, out _, path, AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read | ShareAccess.Write,
        CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_ALERT, null);
    using var ms = new MemoryStream(); long off = 0;
    while (store.ReadFile(out var data, h, off, 60 * 1024) == NTStatus.STATUS_SUCCESS && data is { Length: > 0 }) { ms.Write(data); off += data.Length; }
    store.CloseFile(h);
    return ms.ToArray();
}
Walk(Root);
client.Logoff(); client.Disconnect();
Console.Error.WriteLine($"Freigabe: {csvCount} CSV-Dateien, {files.Count} verschiedene Bewegungen darin");

// ---------------------------------------------------------------- 3. SAP: gebuchte Bewegungen (Referenz ES-<Nr>)
var booked = new Dictionary<int, List<(string Doc, string Reversal, string Status)>>();
var sapRead = Path.Combine(Environment.GetEnvironmentVariable("HOME")!, "repos/tools/sap-tools/SapRead");
var psi = new ProcessStartInfo("dotnet", ["run", "--project", sapRead, "--no-build", "--", "table", "BKPF",
    $"BUKRS = '298' AND XBLNR LIKE 'ES-%' AND BUDAT >= '{from.AddDays(-30):yyyyMMdd}'", "XBLNR", "BELNR", "GJAHR", "STBLG", "BSTAT"])
    { RedirectStandardOutput = true, Environment = { ["SAPSYS"] = "MEP" } };
using (var p = Process.Start(psi)!)
{
    foreach (var line in (await p.StandardOutput.ReadToEndAsync()).Split('\n').Where(l => l.StartsWith("   ") && l.Contains('|')))
    {
        var c = line.Split('|').Select(x => x.Trim()).ToArray();
        if (c.Length >= 5 && c[0].StartsWith("ES-") && int.TryParse(c[0][3..], out var nr))
            (booked.TryGetValue(nr, out var l) ? l : booked[nr] = []).Add(($"{c[1].TrimStart('0')}/{c[2]}", c[3], c[4]));
    }
    await p.WaitForExitAsync();
}
Console.Error.WriteLine($"SAP: {booked.Count} Bewegungen mit Buchung (BKPF ES-*)");

// ---------------------------------------------------------------- 4. Einordnen
string StatusOf(int nr, out string? doc)
{
    doc = null;
    if (booked.TryGetValue(nr, out var docs))
    {
        var active = docs.FirstOrDefault(x => x.Reversal.Length == 0 && x.Status.Length == 0);
        if (active.Doc is not null) { doc = active.Doc; return "Gebucht"; }
        doc = docs[0].Doc;
        return "Storniert";
    }
    return files.ContainsKey(nr) ? "Exportiert" : "Fehlt";
}
var rows = relevant.Values.OrderBy(m => m.MovementDate).Select(m =>
{
    var status = StatusOf(m.MovementNumber, out var doc);
    return (m, status, doc, files: files.GetValueOrDefault(m.MovementNumber) ?? []);
}).ToList();

Console.WriteLine($"\nBewegungen {from:dd.MM.yyyy}–{today:dd.MM.yyyy}: {movements.Count} in esERP, {relevant.Count} gehen laut Mapper an SAP " +
                  $"({movements.Count - relevant.Count} bewusst nicht: ohne Menge bzw. ohne Kostenstelle)");
foreach (var g in rows.GroupBy(r => r.status).OrderBy(g => g.Key)) Console.WriteLine($"  {g.Key,-11} {g.Count(),6}");
Console.WriteLine("\nNicht gebucht je Tag (Fehlt = nie in einer Datei, Exportiert = in einer Datei, aber nicht gebucht):");
foreach (var day in rows.Where(r => r.status is "Fehlt" or "Exportiert").GroupBy(r => DateOnly.FromDateTime(r.m.MovementDate)).OrderBy(g => g.Key))
    Console.WriteLine($"  {day.Key:ddd dd.MM.}  Fehlt {day.Count(r => r.status == "Fehlt"),4}   Exportiert {day.Count(r => r.status == "Exportiert"),4}" +
                      $"   (Uhrzeiten {day.Min(r => r.m.MovementDate):HH:mm}–{day.Max(r => r.m.MovementDate):HH:mm})");

Directory.CreateDirectory("out");
var report = $"out/bewegungen_{today:yyyyMMdd}.csv";
await File.WriteAllLinesAsync(report, ["Bewegung;Datum;Status;SAP-Beleg;Dateien;Lager;Artikel;Menge",
    .. rows.Select(r => $"{r.m.MovementNumber};{r.m.MovementDate:yyyy-MM-dd HH:mm};{r.status};{r.doc};{string.Join(" | ", r.files)};{r.m.WarehouseNumber};{r.m.ArticleNumber};{r.m.Quantity.ToString(CultureInfo.GetCultureInfo("de-DE"))}")],
    new UTF8Encoding(true));
Console.WriteLine($"\nListe: {Path.GetFullPath(report)}");

// ---------------------------------------------------------------- 5. Bewegungsbuch befüllen
if (!write) { Console.WriteLine("Bewegungsbuch unverändert (ohne --write)."); return; }
var mongo = new MongoClient((await kv.GetSecretAsync("MongoDBConnectionString")).Value.Value).GetDatabase("Prod-ES-Worker")
    .GetCollection<BsonDocument>("Accounting-Movements");
var now = DateTime.UtcNow;
var ops = rows.Select(r => new ReplaceOneModel<BsonDocument>(new BsonDocument("_id", r.m.MovementNumber), new BsonDocument
{
    ["_id"] = r.m.MovementNumber, ["Date"] = r.m.MovementDate, ["Status"] = r.status,
    ["File"] = r.files.LastOrDefault() is { } f ? f : BsonNull.Value, ["SapDocument"] = r.doc is null ? BsonNull.Value : r.doc,
    ["ExportedAtUtc"] = BsonNull.Value, ["UpdatedAtUtc"] = now, ["Source"] = "Bestandsaufnahme"
}) { IsUpsert = true }).ToList();
var result = await mongo.BulkWriteAsync(ops);
Console.WriteLine($"Bewegungsbuch: {result.Upserts.Count} neu, {result.ModifiedCount} aktualisiert (Prod-ES-Worker/Accounting-Movements)");
