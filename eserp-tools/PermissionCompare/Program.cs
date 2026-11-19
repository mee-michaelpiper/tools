// Rechte-Vergleich vor dem Wechsel des SiSe-Portals auf Meesenburg.SiSe.Authorization (19.11.2026):
// 1. Rollen und Zuweisungen aus Prod-ES-Portal NUR LESEN (MONGO_CS, Key Vault MongoDBConnectionString)
// 2. in eine lokale Kopie schreiben (LOCAL_CS, z. B. Aspire-Mongo des Shops) – nur dort schreiben die Pakete (Indizes, Startrollen, Merker)
// 3. für jede Person, jede Entra-Gruppe, „alle Angemeldeten“ und Developer die Rechte mit altem und neuem Paket auflösen und vergleichen
// 4. zeigen, was das neue Paket beim ersten Start an den Startrollen ändert (soll: nur der Merker SeededPermissions, keine Rechte)
// Aufruf: MONGO_CS=… LOCAL_CS=… GITHUB_PACKAGES_TOKEN=… dotnet run
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting.Internal;
using Microsoft.Extensions.Logging.Abstractions;
using MongoDB.Driver;
using Old = Meesenburg.ES.Authorization;
using New = Meesenburg.SiSe.Authorization;

const string CopyDb = "PermCompare-Prod-ES-Portal";
var prod = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS")).GetDatabase("Prod-ES-Portal");
var local = new MongoClient(Environment.GetEnvironmentVariable("LOCAL_CS"));
await local.DropDatabaseAsync(CopyDb);
var copy = local.GetDatabase(CopyDb);

// 1+2: Kopie (Rollen, Zuweisungen, Merker) – Prod nur lesen
foreach (var name in new[] { "Roles", "RoleAssignments", "PermissionMeta" })
{
    var docs = await prod.GetCollection<MongoDB.Bson.BsonDocument>(name).Find(_ => true).ToListAsync();
    if (docs.Count > 0) await copy.GetCollection<MongoDB.Bson.BsonDocument>(name).InsertManyAsync(docs);
    Console.WriteLine($"{name}: {docs.Count} kopiert");
}
var rolesBefore = await copy.GetCollection<New.PortalRole>("Roles").Find(_ => true).ToListAsync();
var assignments = await copy.GetCollection<New.RoleAssignment>("RoleAssignments").Find(_ => true).ToListAsync();

var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["ConnectionStrings:portalMongo"] = Environment.GetEnvironmentVariable("LOCAL_CS") }).Build();
var env = new HostingEnvironment { EnvironmentName = "Development", ApplicationName = "PermissionCompare" };

// Alt: Paket 1.0.15 wie im Betrieb (eigener Store, eigene Startrollen-Logik)
var oldOptions = new Old.PermissionOptions { Database = CopyDb };
var oldDb = new Old.PortalDatabase(oldOptions, config, env);
var oldStore = new Old.PermissionStore(oldDb, new Old.AuditLog(oldDb, env, NullLogger<Old.AuditLog>.Instance), NullLogger<Old.PermissionStore>.Instance);
var oldResolver = new Old.PermissionResolver(oldStore, oldOptions);

// Neu: Paket mit ES-Katalog (inhaltlich = Old.Permissions.Catalog), Auflösung als reine Regel auf denselben Daten
var catalog = new New.PermissionCatalog([new New.StaticPermissionCatalog(Old.Permissions.Catalog.Select(p => new New.PermissionInfo(p.Name, p.Area, p.Title, p.Description)))]);
var developer = new New.PermissionOptions().DeveloperRole;

var subjects = new List<(string Label, string? Oid, string[] Roles)> { ("alle Angemeldeten (ohne Zuweisung)", null, []), ("Developer", null, [developer]) };
subjects.AddRange(assignments.Where(a => a.SubjectType == New.SubjectType.User).Select(a => a.SubjectId).Distinct()
    .Select(oid => ($"Person {assignments.First(a => a.SubjectId == oid).SubjectName ?? oid}", (string?)oid, Array.Empty<string>())));
subjects.AddRange(assignments.Where(a => a.SubjectType == New.SubjectType.EntraRole).Select(a => a.SubjectId).Distinct()
    .Select(g => ($"Gruppe {g}", (string?)null, new[] { g })));

var differences = 0;
foreach (var (label, oid, roles) in subjects)
{
    var before = (await oldResolver.ResolveAsync(oid, roles)).Permissions.OrderBy(p => p).ToList();
    var after = New.PermissionResolver.Resolve(oid, roles, rolesBefore, assignments, developer, catalog).Permissions.OrderBy(p => p).ToList();
    if (before.SequenceEqual(after)) continue;
    differences++;
    Console.WriteLine($"ABWEICHUNG {label}: nur alt [{string.Join(", ", before.Except(after))}], nur neu [{string.Join(", ", after.Except(before))}]");
}
Console.WriteLine($"{subjects.Count} Fälle verglichen (alle Angemeldeten, Developer, {subjects.Count - 2} Personen/Gruppen) – Abweichungen: {differences}");

// 4: Erster Start des neuen Pakets auf der Kopie
var newOptions = new New.PermissionOptions { Database = CopyDb };
var newDb = new New.PortalDatabase(newOptions, config, env);
var newStore = new New.PermissionStore(newDb, new New.AuditLog(newDb, env, NullLogger<New.AuditLog>.Instance),
    PermissionCompareSeed.EsPermissionSeedForCompare.Create(), NullLogger<New.PermissionStore>.Instance);
var rolesAfter = await newStore.SelectRolesAsync();
var changed = 0;
foreach (var r in rolesAfter)
{
    var b = rolesBefore.FirstOrDefault(x => x.Id == r.Id);
    if (b is null) { Console.WriteLine($"NEUE ROLLE {r.Id}"); changed++; continue; }
    if (!b.Permissions.OrderBy(p => p).SequenceEqual(r.Permissions.OrderBy(p => p)))
    { Console.WriteLine($"RECHTE GEÄNDERT {r.Id}: vorher [{string.Join(", ", b.Permissions)}] nachher [{string.Join(", ", r.Permissions)}]"); changed++; }
}
Console.WriteLine($"Erster Start neues Paket: {rolesAfter.Count(r => r.SeededPermissions.Count > 0)} Startrollen mit Merker, Rechte geändert: {changed}");
await local.DropDatabaseAsync(CopyDb);
return differences + changed == 0 ? 0 : 1;
