// Nur lesen (16.11.2026): Materialbewegungen esERP ↔ Übergabedateien seit 01.09.2026 – fehlende, doppelte, geänderte; Nummernfolge.
// Gebucht = steht in einer Datei unter „verarbeitet“ (Processed). Andere Ordner nur zur Info (abgelehnt/Prüfung/Eingang/ersetzt).
// Aufruf: dotnet run [-- csv-ausgabe.csv]
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Meesenburg.ES.API.SAPData.Models.AccountingTransfer;
using Meesenburg.ES.API.SAPData.Services.AccountingTransfer;
using Meesenburg.ES.DataWorker.Services;
using Meesenburg.Infrastructure.KeyVault.Providers;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using WorkerMat = Meesenburg.ES.DataWorker.Models.EsApi.AccountingMat;

var kv = new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential());
var cache = new MemoryCache(new MemoryCacheOptions());
var share = new TransferShare(new KeyVaultSecretProvider(kv, cache, NullLogger<KeyVaultSecretProvider>.Instance),
    Options.Create(new AccountingTransferOptions()), NullLogger<TransferShare>.Instance);

// --- Dateien
var files = await share.ListAndReadAsync([TransferFolder.Processed, TransferFolder.Failed, TransferFolder.Review, TransferFolder.Inbox, TransferFolder.Replaced],
    f => f.Name.StartsWith("SAP_Export_2026", StringComparison.OrdinalIgnoreCase) && string.CompareOrdinal(f.Name, "SAP_Export_20260901") >= 0);
Console.WriteLine($"Dateien: {files.Count} ({string.Join(", ", files.GroupBy(f => f.File.Folder).Select(g => $"{g.Key} {g.Count()}"))})");
// Referenz → Liste (Ordner, Datei, Blockzeilen)
var inFiles = new Dictionary<int, List<(TransferFolder Folder, string File, List<string> Lines)>>();
foreach (var (file, content) in files)
    foreach (var (reference, lines) in Blocks(TransferCsv.Decode(content).Replace("\r\n", "\n").Split('\n')))
        if (reference.StartsWith("ES-") && int.TryParse(reference[3..], out var no))
        {
            if (!inFiles.TryGetValue(no, out var list)) inFiles[no] = list = [];
            list.Add((file.Folder, file.Name, lines));
        }

// --- esERP
var creds = JsonDocument.Parse((await kv.GetSecretAsync("c4vApiCredentials-prod")).Value.Value).RootElement;
var http = new HttpClient { BaseAddress = new Uri("https://esapi.meesenburg.de"), Timeout = TimeSpan.FromMinutes(10) };
var login = await http.PostAsJsonAsync("/login", new { username = creds.GetProperty("username").GetString(), token = creds.GetProperty("token").GetString() });
login.EnsureSuccessStatusCode();
http.DefaultRequestHeaders.Authorization = new("Bearer", JsonDocument.Parse(await login.Content.ReadAsStringAsync()).RootElement.GetProperty("token").GetString());
var json = await http.GetStringAsync($"/lager/bewegungen?datumVon=2026-09-01T00:00:00&datumBis={DateTime.Now.AddDays(1):yyyy-MM-dd}T00:00:00&pageNumber=1&pageSize=500000");
var root = JsonDocument.Parse(json).RootElement;
var mats = JsonSerializer.Deserialize<List<WorkerMat>>((root.ValueKind == JsonValueKind.Array ? root : root.GetProperty("items")).GetRawText())!
    .DistinctBy(m => m.MovementNumber).OrderBy(m => m.MovementNumber).ToList();
Console.WriteLine($"esERP-Bewegungen 01.09.–heute: {mats.Count}, Nummern {mats.First().MovementNumber}–{mats.Last().MovementNumber}");

// Nummernfolge vs. Zeit
var byDate = mats.OrderBy(m => m.MovementDate).ToList();
var inversions = byDate.Zip(byDate.Skip(1)).Count(p => p.Second.MovementNumber < p.First.MovementNumber);
var gaps = mats.Zip(mats.Skip(1)).Where(p => p.Second.MovementNumber - p.First.MovementNumber > 1).Sum(p => p.Second.MovementNumber - p.First.MovementNumber - 1);
Console.WriteLine($"Nummern nach Zeit sortiert: {inversions} Rücksprünge; Nummernlücken im Bestand: {gaps} Nummern (nicht geliefert/anders vergeben)");

var mapper = new AccountingMatToSapMapper();
var rendered = new Dictionary<int, List<string>>();
foreach (var m in mats)
{
    if (mapper.MapToSapDocument(m) is not { } doc) continue;
    using var ms = new MemoryStream();
    new SapCsvWriter().WriteDocuments(ms, [doc], includeTemplateHeaderRows: false);
    rendered[m.MovementNumber] = Encoding.UTF8.GetString(ms.ToArray()).Replace("\r\n", "\n").Split('\n').Where(l => l.Length > 0).ToList();
}
Console.WriteLine($"davon mit Wert (würden übergeben): {rendered.Count}, ohne Wert (0 €): {mats.Count - rendered.Count}");

// Gebuchte Dateien: Nummernbereich je Datei (für „gehört in welche Datei“)
var processedRanges = inFiles.SelectMany(x => x.Value.Where(v => v.Folder == TransferFolder.Processed).Select(v => (No: x.Key, v.File)))
    .GroupBy(x => x.File).Select(g => (File: g.Key, Min: g.Min(x => x.No), Max: g.Max(x => x.No))).OrderBy(r => r.Min).ToList();
string Neighbour(int no) => processedRanges.FirstOrDefault(r => no >= r.Min && no <= r.Max) is { File: not null } r ? $"im Bereich von {r.File}" :
    processedRanges.LastOrDefault(r => r.Max < no) is { File: not null } before ? $"nach {before.File}" : "vor der ersten Datei";

var report = new List<string> { "Art;Bewegung;Datum;Betrag;Bewegungsart;Auftrag;Info;Dateien" };
string Desc(WorkerMat m) => $"{m.MovementDate:dd.MM.yyyy HH:mm};{m.PurchasePrice * m.Quantity:0.00};{m.MovementDescription};{m.OrderNumber}";

int missing = 0, missingPending = 0, doubles = 0, changed = 0, zeroBooked = 0;
foreach (var m in mats)
{
    var where = inFiles.GetValueOrDefault(m.MovementNumber) ?? [];
    var booked = where.Where(w => w.Folder == TransferFolder.Processed).ToList();
    var hasValue = rendered.TryGetValue(m.MovementNumber, out var now);
    if (hasValue && booked.Count == 0)
    {
        var pending = where.Where(w => w.Folder is TransferFolder.Failed or TransferFolder.Review or TransferFolder.Inbox).ToList();
        if (pending.Count > 0) missingPending++; else missing++;
        report.Add($"{(pending.Count > 0 ? "noch nicht gebucht" : "fehlt")};{m.MovementNumber};{Desc(m)};{Neighbour(m.MovementNumber)};{string.Join(" ", where.Select(w => $"{w.Folder}/{w.File}"))}");
    }
    if (booked.Select(b => b.File).Distinct().Count() > 1)
    {
        doubles++;
        report.Add($"doppelt gebucht;{m.MovementNumber};{Desc(m)};;{string.Join(" ", booked.Select(b => b.File))}");
    }
    if (booked.Count > 0 && hasValue && !booked[0].Lines.SequenceEqual(now!))
    {
        changed++;
        report.Add($"seitdem geändert;{m.MovementNumber};{Desc(m)};;{booked[0].File}: {string.Join(" | ", booked[0].Lines.Skip(1))} → jetzt {string.Join(" | ", now!.Skip(1))}");
    }
    if (booked.Count > 0 && !hasValue)
    {
        zeroBooked++;
        report.Add($"gebucht, jetzt 0 €;{m.MovementNumber};{Desc(m)};;{string.Join(" ", booked.Select(b => b.File))}");
    }
}
var unknown = inFiles.Keys.Where(k => mats.All(m => m.MovementNumber != k) && k >= mats.First().MovementNumber).ToList();
foreach (var k in unknown)
    report.Add($"in Datei, esERP liefert nicht;{k};;;;;;{string.Join(" ", inFiles[k].Select(w => $"{w.Folder}/{w.File}"))}");

Console.WriteLine($"Fehlen (mit Wert, in keiner gebuchten und keiner offenen Datei): {missing}");
Console.WriteLine($"Noch nicht gebucht (nur in abgelehnt/Prüfung/Eingang): {missingPending}");
Console.WriteLine($"Doppelt gebucht (in mehreren gebuchten Dateien): {doubles}");
Console.WriteLine($"Gebucht, aber in esERP seitdem geändert: {changed}");
Console.WriteLine($"Gebucht, jetzt 0 €: {zeroBooked}");
Console.WriteLine($"In Dateien, von esERP nicht (mehr) geliefert: {unknown.Count}");
var output = args.Length > 0 ? args[0] : "materialabgleich.csv";
await File.WriteAllLinesAsync(output, report, new UTF8Encoding(true));
Console.WriteLine($"Liste: {Path.GetFullPath(output)}");
foreach (var r in report.Skip(1).Where(r => !r.StartsWith("seitdem geändert")).Take(60)) Console.WriteLine("  " + r);
return 0;

static bool IsItem(string line) => int.TryParse(line.Split(';')[0].Trim(), out var k) && k is >= 1 and <= 50;
static Dictionary<string, List<string>> Blocks(IEnumerable<string> lines)
{
    var result = new Dictionary<string, List<string>>();
    List<string>? current = null;
    foreach (var raw in lines)
    {
        var line = raw.TrimEnd('\r');
        if (line.StartsWith("K;")) { current = []; result[line.Split(';') is { Length: > 7 } c ? c[7].Trim().ToUpperInvariant() : ""] = current; }
        if (current is not null && (line.StartsWith("K;") || IsItem(line))) current.Add(line);
    }
    return result;
}
