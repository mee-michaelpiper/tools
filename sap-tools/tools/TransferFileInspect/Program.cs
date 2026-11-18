// Nur lesen: alle Fassungen einer Übergabedatei (alle Ordner) mit Zeilen zu bestimmten Referenzen zeigen.
// Aufruf: dotnet run -- <Namensteil> [Referenz ...]
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Meesenburg.ES.API.SAPData.Services.AccountingTransfer;
using Meesenburg.ES.API.SAPData.Models.AccountingTransfer;
using Meesenburg.Infrastructure.KeyVault.Providers;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

var cache = new MemoryCache(new MemoryCacheOptions());
var secrets = new KeyVaultSecretProvider(new SecretClient(new Uri("https://kv-meesenburg-prod.vault.azure.net/"), new AzureCliCredential()), cache,
    NullLogger<KeyVaultSecretProvider>.Instance);
var share = new TransferShare(secrets, Options.Create(new AccountingTransferOptions()), NullLogger<TransferShare>.Instance);
var part = args[0];
var refs = args.Skip(1).ToHashSet();
var files = await share.ListAndReadAsync([TransferFolder.Processed, TransferFolder.Failed, TransferFolder.Review, TransferFolder.Inbox, TransferFolder.Replaced],
    f => f.Name.Contains(part, StringComparison.OrdinalIgnoreCase));
foreach (var (file, content) in files)
{
    Console.WriteLine($"== {file.Folder} {file.Name} {file.ModifiedUtc:u}");
    var lines = TransferCsv.ReadLines(TransferCsv.Decode(content));
    var show = false;
    foreach (var l in lines)
    {
        if (TransferCsv.IsHeader(l)) show = refs.Count == 0 || refs.Contains(TransferCsv.Cell(l, TransferCsv.HReference));
        if (show) Console.WriteLine($"  {l.LineNumber}: {string.Join(";", l.Cells)}");
    }
}
