// Vergleicht eine aus der Quelle gebaute DLL mit der DLL des veröffentlichten Pakets (~/.nuget/packages):
// öffentliche Typen/Member und die IL-Größe jeder Methode. Zweck (19.11.2026): bevor ein Paket durch einen Projektverweis ersetzt wird,
// sicherstellen, dass die Quelle nicht unbemerkt vom veröffentlichten Stand abweicht.
// Aufruf: dotnet run -- <gebaut.dll> <paket.dll>
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;

static Dictionary<string, int> Read(string path)
{
    using var pe = new PEReader(File.OpenRead(path));
    var md = pe.GetMetadataReader();
    var result = new Dictionary<string, int>();
    foreach (var th in md.TypeDefinitions)
    {
        var t = md.GetTypeDefinition(th);
        var typeName = md.GetString(t.Namespace) + "." + md.GetString(t.Name);
        if (typeName.Contains('<')) continue; // Compiler-Hilfstypen
        foreach (var mh in t.GetMethods())
        {
            var m = md.GetMethodDefinition(mh);
            var name = md.GetString(m.Name);
            var sig = Convert.ToHexString(md.GetBlobBytes(m.Signature));
            var size = m.RelativeVirtualAddress == 0 ? -1 : pe.GetMethodBody(m.RelativeVirtualAddress).Size;
            result[$"{typeName}::{name}({sig})"] = size;
        }
    }
    return result;
}

var built = Read(args[0]);
var published = Read(args[1]);
var missing = published.Keys.Except(built.Keys).ToList();
var added = built.Keys.Except(published.Keys).ToList();
var changed = built.Keys.Intersect(published.Keys).Where(k => built[k] != published[k]).ToList();
foreach (var k in missing) Console.WriteLine($"  nur im Paket: {k}");
foreach (var k in added) Console.WriteLine($"  nur in der Quelle: {k}");
foreach (var k in changed) Console.WriteLine($"  IL-Größe {published[k]} → {built[k]}: {k}");
Console.WriteLine($"{Path.GetFileName(args[0])}: {published.Count} Methoden im Paket, fehlt {missing.Count}, neu {added.Count}, geändert {changed.Count}");
return missing.Count + added.Count + changed.Count == 0 ? 0 : 1;
