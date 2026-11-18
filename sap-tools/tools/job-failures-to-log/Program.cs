// Fehlgeschlagene Jobs (Prod-ES-Worker/Jobs, Status 4) als Log-Einträge nachtragen (Prod-ES-Logs/Logs), damit die
// Störungsstatistik („Fehler & Log → Störungen“) auch Fehler vor dem 15.10.2026 sieht – bis dahin wurden endgültige
// Job-Fehler nicht geloggt. Gekennzeichnet mit Properties.Backfilled = true und Properties.JobId (keine Dubletten).
//   MONGO_CS=… dotnet run -- [Tage=90]            → nur anzeigen
//   MONGO_CS=… dotnet run -- [Tage=90] --write    → schreiben (Prod nur nach Freigabe!)
using Meesenburg.ES.ServiceDefaults.Monitoring;
using MongoDB.Bson;
using MongoDB.Driver;

var days = args.FirstOrDefault(a => int.TryParse(a, out _)) is { } d ? int.Parse(d) : 90;
var write = args.Contains("--write");
var client = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var jobs = client.GetDatabase("Prod-ES-Worker").GetCollection<BsonDocument>("Jobs");
var logs = client.GetDatabase("Prod-ES-Logs").GetCollection<BsonDocument>("Logs");
string[] types = ["?", "Customer", "Vendor", "Article", "Employee", "Accounting", "InvoiceMail", "MaterialCatalog", "InvoiceDispatch", "SearchIndex"];

var since = DateTime.UtcNow.AddDays(-days);
var failed = await jobs.Find(new BsonDocument { { "Status", 4 }, { "LastError", new BsonDocument("$ne", BsonNull.Value) } }).ToListAsync();
var existing = (await logs.Find(new BsonDocument("Properties.Backfilled", true))
        .Project(new BsonDocument("Properties.JobId", 1)).ToListAsync())
    .Select(x => x["Properties"]["JobId"].AsString).ToHashSet();

static DateTime? When(BsonDocument j, string field)
    => j.TryGetValue(field, out var v) && v.IsBsonDocument && v["DateTime"].IsValidDateTime ? v["DateTime"].ToUniversalTime() : null;

var docs = new List<BsonDocument>();
var byResource = new Dictionary<string, int>();
foreach (var j in failed)
{
    var at = When(j, "FinishedAtUtc") ?? When(j, "LastHeartbeatUtc") ?? When(j, "RequestedAtUtc");
    if (at is null || at < since) continue;
    var id = j["_id"].AsGuid.ToString();
    if (existing.Contains(id)) continue;
    var error = j["LastError"].AsString;
    var type = j["JobType"].ToInt32() is var t && t < types.Length ? types[t] : t.ToString();
    // Ausnahmetyp ist nicht gespeichert – für Verbindungsfehler den passenden annehmen, sonst allgemein
    var exType = error.Contains("Connection refused") || error.Contains("timed out") || error.Contains("HttpClient.Timeout")
        ? "System.Net.Http.HttpRequestException" : error.Contains("STATUS_") ? "System.IO.IOException" : "System.Exception";
    var resource = ResourceFaults.Classify(exType, error, null, "ESDataWorker.Models.Jobs.EsWorkerMessageHandler", error, "es-dataworker");
    byResource[resource?.Key ?? "(keine Ressource)"] = byResource.GetValueOrDefault(resource?.Key ?? "(keine Ressource)") + 1;
    var doc = new BsonDocument
    {
        { "Timestamp", at.Value }, { "Service", "es-dataworker" }, { "Environment", "Production" },
        { "Instance", j.TryGetValue("WorkerInstance", out var w) && w.IsString ? w.AsString : "unbekannt" },
        { "Level", "Error" }, { "LevelValue", 4 }, { "Category", "ESDataWorker.Models.Jobs.EsWorkerMessageHandler" },
        { "Message", $"{type}-Job {id} fehlgeschlagen: {error} (nachgetragen)" },
        { "Template", "{JobType}-Job {JobId} fehlgeschlagen: {Error}" },
        { "Properties", new BsonDocument { { "JobType", type }, { "JobId", id }, { "Error", error }, { "Backfilled", true } } },
        { "Exception", new BsonDocument { { "Type", exType }, { "Message", error }, { "Details", $"{exType}: {error}" } } }
    };
    if (resource is not null) doc.Add("Resource", resource.Key);
    docs.Add(doc);
}

Console.WriteLine($"{docs.Count} fehlgeschlagene Jobs der letzten {days} Tage nachzutragen ({existing.Count} schon nachgetragen):");
foreach (var (k, v) in byResource.OrderByDescending(x => x.Value)) Console.WriteLine($"  {v,5}  {k}");
if (!write) { Console.WriteLine("Nur angezeigt – mit --write schreiben."); return; }
if (docs.Count > 0) await logs.InsertManyAsync(docs);
Console.WriteLine($"geschrieben: {docs.Count}");
