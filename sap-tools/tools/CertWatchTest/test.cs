// Prüft die Zertifikatsüberwachung des Portals (CertificateWatchService) mit der Endpunktliste aus Web/appsettings.json – nur lesen (TLS-Handshake).
//   dotnet run test.cs   (aus diesem Ordner, VPN an)
#:project ../../../../Meesenburg.ES/Meesenburg.ES.Web
#:property PublishAot=false
using Meesenburg.ES.Web.Services.Dashboard;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

var config = new ConfigurationBuilder().AddJsonFile(Path.GetFullPath("../../../../Meesenburg.ES/src/Meesenburg.ES.Web/appsettings.json")).Build();
var svc = new CertificateWatchService(config, new MemoryCache(new MemoryCacheOptions()), NullLogger<CertificateWatchService>.Instance);
foreach (var c in (await svc.RetrieveAsync()).OrderBy(c => c.DaysLeft ?? int.MinValue))
    Console.WriteLine($"{c.Endpoint.Name,-24} {c.Endpoint.Host}:{c.Endpoint.Port,-6} {(c.NotAfterUtc is { } n ? $"{n:dd.MM.yyyy} noch {c.DaysLeft,4} Tage  {c.Issuer}  {c.PolicyErrors}" : "nicht lesbar: " + c.Error)}");
