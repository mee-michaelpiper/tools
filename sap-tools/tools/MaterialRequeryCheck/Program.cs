// Nur lesen (16.11.2026): Liefert esERP die Materialbewegungen einer Übergabedatei beim erneuten Abruf genauso?
// Liest die Datei (Freigabe), das Zeitfenster des Exports (Mongo Accounting-Exports), ruft /lager/bewegungen erneut ab
// (1. gleiches Fenster wie damals, 2. weites Fenster wie „Neu abfragen“: 2 Tage vor der ältesten Bewegung bis jetzt),
// schreibt sie mit Mapper + SapCsvWriter des Workers und vergleicht jede ES-Zeile mit der Datei.
// Aufruf: MONGO_CS=… dotnet run -- SAP_Export_20261111_183011.csv
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
using MongoDB.Bson;
using MongoDB.Driver;
using WorkerMat = Meesenburg.ES.DataWorker.Models.EsApi.AccountingMat;

var fileName = args[0];
var kv = new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential());
var cache = new MemoryCache(new MemoryCacheOptions());
var share = new TransferShare(new KeyVaultSecretProvider(kv, cache, NullLogger<KeyVaultSecretProvider>.Instance),
    Options.Create(new AccountingTransferOptions()), NullLogger<TransferShare>.Instance);

// 1) Datei (erste Fundstelle) – ES-Blöcke: Referenz → Zeilen
var files = await share.ListAndReadAsync([TransferFolder.Failed, TransferFolder.Review, TransferFolder.Processed, TransferFolder.Replaced],
    f => string.Equals(f.Name, fileName, StringComparison.OrdinalIgnoreCase));
if (files.Count == 0) { Console.WriteLine("Datei nicht gefunden"); return 1; }
var (file, content) = files[0];
Console.WriteLine($"Datei: {file.Folder}/{file.Name}");
var text = TransferCsv.Decode(content).Replace("\r\n", "\n");
var fileBlocks = Blocks(text.Split('\n'));
var fileMaterials = fileBlocks.Where(b => b.Key.StartsWith("ES-")).ToDictionary(b => b.Key, b => b.Value);
Console.WriteLine($"Belege in der Datei: {fileBlocks.Count}, davon Materialbewegungen: {fileMaterials.Count}");
var broken = text.Split('\n').Select((l, i) => (l, i)).Where(x => x.l.Length > 0 && !x.l.StartsWith("K;") && !IsItem(x.l) && x.i > 1).ToList();
foreach (var (l, i) in broken) Console.WriteLine($"  zerbrochene Zeile {i + 1}: {l}");

// 2) Zeitfenster des Exports
var mongo = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var export = await mongo.GetDatabase("Prod-ES-Worker").GetCollection<BsonDocument>("Accounting-Exports")
    .Find(new BsonDocument { { "FileName", fileName }, { "Kind", "Export" } }).FirstOrDefaultAsync();
DateTime? winFrom = export?["MaterialsFromUtc"].ToUniversalTime(), winTo = export?["MaterialsToUtc"].ToUniversalTime();
Console.WriteLine($"Exportfenster (UTC): {winFrom:dd.MM.yyyy HH:mm:ss} – {winTo:dd.MM.yyyy HH:mm:ss}");

// 3) esERP-Login (Zugangsdaten aus dem Key Vault, nicht ausgeben)
var creds = JsonDocument.Parse((await kv.GetSecretAsync("c4vApiCredentials-prod")).Value.Value).RootElement;
var http = new HttpClient { BaseAddress = new Uri("https://esapi.meesenburg.de"), Timeout = TimeSpan.FromMinutes(3) };
var login = await http.PostAsJsonAsync("/login", new { username = creds.GetProperty("username").GetString(), token = creds.GetProperty("token").GetString() });
login.EnsureSuccessStatusCode();
var token = JsonDocument.Parse(await login.Content.ReadAsStringAsync()).RootElement.GetProperty("token").GetString();
http.DefaultRequestHeaders.Authorization = new("Bearer", token);

async Task<List<WorkerMat>> Fetch(DateTimeOffset from, DateTimeOffset to)
{
    // wie C4VApiBroker: {fromDate:s}
    var json = await http.GetStringAsync($"/lager/bewegungen?datumVon={from:s}&datumBis={to:s}&pageNumber=1&pageSize=500000");
    var root = JsonDocument.Parse(json).RootElement;
    var items = root.ValueKind == JsonValueKind.Array ? root : root.GetProperty("items");
    return JsonSerializer.Deserialize<List<WorkerMat>>(items.GetRawText())!;
}

Dictionary<string, List<string>> Render(IEnumerable<WorkerMat> mats)
{
    var mapper = new AccountingMatToSapMapper();
    var docs = mats.Select(m => mapper.MapToSapDocument(m)).OfType<ESDataWorker.Models.SapFiDocument>().ToList();
    using var ms = new MemoryStream();
    new SapCsvWriter().WriteDocuments(ms, docs, includeTemplateHeaderRows: false);
    return Blocks(Encoding.UTF8.GetString(ms.ToArray()).Replace("\r\n", "\n").Split('\n'));
}

void Compare(string title, Dictionary<string, List<string>> fresh)
{
    int same = 0, differ = 0, missing = 0;
    foreach (var (reference, lines) in fileMaterials)
    {
        if (!fresh.TryGetValue(reference, out var now)) { missing++; Console.WriteLine($"  fehlt: {reference}"); continue; }
        if (now.SequenceEqual(lines)) same++;
        else
        {
            differ++;
            if (differ <= 5) Console.WriteLine($"  anders: {reference}\n    Datei: {string.Join(" | ", lines)}\n    neu:   {string.Join(" | ", now)}");
        }
    }
    var extraKeys = fresh.Keys.Where(k => !fileMaterials.ContainsKey(k)).ToList();
    var extra = extraKeys.Count;
    foreach (var k in extraKeys) Console.WriteLine($"  zusätzlich: {string.Join(" | ", fresh[k])}");
    Console.WriteLine($"{title}: gleich {same}, anders {differ}, fehlt {missing} (zusätzlich geliefert: {extra})");
}

if (winFrom is not null && winTo is not null)
    Compare("Gleiches Fenster wie der Export", Render(await Fetch(new DateTimeOffset(winFrom.Value, TimeSpan.Zero), new DateTimeOffset(winTo.Value, TimeSpan.Zero))));
var dates = fileMaterials.Values.Select(v => DateTime.ParseExact(v[0].Split(';')[1], "dd.MM.yyyy", null)).ToList();
if (dates.Count > 0)
{
    var wide = await Fetch(new DateTimeOffset(dates.Min().AddDays(-2)), DateTimeOffset.Now.AddDays(1));
    var wanted = fileMaterials.Keys.Select(k => int.Parse(k[3..])).ToHashSet();
    Compare("Weites Fenster (wie „Neu abfragen“)", Render(wide.Where(m => wanted.Contains(m.MovementNumber)).DistinctBy(m => m.MovementNumber)));
}
return 0;

static bool IsItem(string line) => int.TryParse(line.Split(';')[0].Trim(), out var k) && k is >= 1 and <= 50;

static Dictionary<string, List<string>> Blocks(IEnumerable<string> lines)
{
    var result = new Dictionary<string, List<string>>();
    List<string>? current = null;
    foreach (var raw in lines)
    {
        var line = raw.TrimEnd('\r');
        if (line.StartsWith("K;")) { current = []; result[line.Split(';')[7].Trim().ToUpperInvariant()] = current; }
        if (current is not null && (line.StartsWith("K;") || IsItem(line))) current.Add(line);
    }
    return result;
}
