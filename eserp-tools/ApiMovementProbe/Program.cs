// Nur lesen (16.11.2026): Zeigt, wie /lager/bewegungen eine bestimmte Bewegung liefert – je Datumsfenster die rohe Anfrage + Treffer.
// DUMP=<datei> speichert die Rohantwort.
// Aufruf: dotnet run -- 630012991 "2026-10-21T00:00:00|2026-10-22T00:00:00" "2026-11-16T00:00:00|2026-11-17T00:00:00"
using System.Net.Http.Json;
using System.Text.Json;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var number = args.Length > 0 ? args[0] : "630012991";
var windows = args.Length > 1 ? args[1..] : new[] { "2026-10-21T00:00:00|2026-10-22T00:00:00", "2026-11-16T00:00:00|2026-11-17T00:00:00" };
var kv = new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential());
var creds = JsonDocument.Parse((await kv.GetSecretAsync("c4vApiCredentials-prod")).Value.Value).RootElement;
var http = new HttpClient { BaseAddress = new Uri("https://esapi.meesenburg.de"), Timeout = TimeSpan.FromMinutes(5) };
var login = await http.PostAsJsonAsync("/login", new { username = creds.GetProperty("username").GetString(), token = creds.GetProperty("token").GetString() });
login.EnsureSuccessStatusCode();
http.DefaultRequestHeaders.Authorization = new("Bearer", JsonDocument.Parse(await login.Content.ReadAsStringAsync()).RootElement.GetProperty("token").GetString());
foreach (var w in windows)
{
    var p = w.Split('|');
    var url = $"/lager/bewegungen?datumVon={p[0]}&datumBis={p[1]}&pageNumber=1&pageSize=500000";
    var json = await http.GetStringAsync(url);
    var root = JsonDocument.Parse(json).RootElement;
    var items = root.ValueKind == JsonValueKind.Array ? root : root.GetProperty("items");
    if (Environment.GetEnvironmentVariable("DUMP") is { Length: > 0 } dump) await File.WriteAllTextAsync(dump, json);
    var hits = items.EnumerateArray().Where(e => e.GetRawText().Contains(number)).ToList();
    Console.WriteLine($"GET {url}\n  → {items.GetArrayLength()} Bewegungen, Treffer {number}: {hits.Count}");
    foreach (var h in hits) Console.WriteLine("  " + h.GetRawText());
}
