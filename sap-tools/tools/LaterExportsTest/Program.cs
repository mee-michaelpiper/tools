// Test (11.11.2026): AccountingTransferService.FindLaterExportsAsync gegen die echte Freigabe (nur lesen).
// Fall 10.11.: Prüfkopie SAP_Export_20261028_183018.csv – 910010148/018/183/195 standen danach in 20261109_183018, 20261110_080130, 20261110_183011.
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Meesenburg.ES.API.SAPData.Services.AccountingTransfer;
using Meesenburg.Infrastructure.KeyVault.Providers;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

var cache = new MemoryCache(new MemoryCacheOptions());
var secrets = new KeyVaultSecretProvider(new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential()), cache,
    NullLogger<KeyVaultSecretProvider>.Instance);
var share = new TransferShare(secrets, Options.Create(new AccountingTransferOptions()), NullLogger<TransferShare>.Instance);
var service = new AccountingTransferService(share, null!, cache, NullLogger<AccountingTransferService>.Instance);

var fail = 0;
var hits = await service.FindLaterExportsAsync("SAP_Export_20261028_183018.csv", ["910010148", "910010018", "910010183", "910010195", "910010999"]);
foreach (var (r, f) in hits) Console.WriteLine($"{r}: {string.Join(", ", f)}");
foreach (var r in new[] { "910010148", "910010018", "910010183", "910010195" })
    if (!hits.TryGetValue(r, out var files) || !files.Contains("SAP_Export_20261110_080130.csv") || !files.Contains("SAP_Export_20261110_183011.csv")) { fail++; Console.WriteLine("FEHLER: " + r); }
if (hits.ContainsKey("910010999")) { fail++; Console.WriteLine("FEHLER: 910010999 gefunden"); }
var none = await service.FindLaterExportsAsync("SAP_Export_20261109_183018.csv", ["900010703", "900010704"]);
if (none.Count != 0) { fail++; Console.WriteLine("FEHLER: 703/704 " + string.Join(";", none.Keys)); }
Console.WriteLine(fail == 0 ? "alle OK" : $"{fail} Fehler");
return fail;
