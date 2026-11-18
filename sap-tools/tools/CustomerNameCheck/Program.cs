// Eichung der Namensprüfung (PrivateCustomerCheck im Web-Projekt, vorher bauen) an SAP-Kunden.
// Eingabe: Ausgabe von SapRead "table KNA1 ... KUNNR BRSCH NAME1 NAME2 NAME3" (Zeilen „ KUNNR | BRSCH | N1 | N2 | N3“).
//   dotnet run -- <kna1.txt> [Beispiele je Gruppe]
// Zeigt je Branchengruppe, wie oft die Prüfung Behörde/Firma vorschlagen würde, und Beispiele.
using Meesenburg.ES.Web.Models.Customers;
using Meesenburg.ES.Web.Services.Customers;

var samples = args.Length > 1 ? int.Parse(args[1]) : 15;
var rows = File.ReadLines(args[0]).Select(l => l.Split('|')).Where(p => p.Length >= 5)
    .Select(p => (Kunnr: p[0].Trim(), Brsch: p[1].Trim(), N1: p[2].Trim(), N2: p[3].Trim(), N3: p[4].Trim()))
    .Where(r => r.Brsch != "").ToList();
string Group(string b) => b switch { "B33" or "B34" or "B35" => "Behörde (B33-35)", "B38" => "Privat (B38)", _ => "Firma (sonst)" };
foreach (var g in rows.GroupBy(r => Group(r.Brsch)).OrderBy(g => g.Key))
{
    var results = g.Select(r => (r, hints: PrivateCustomerCheck.Check(r.N1, r.N2, r.N3))).ToList();
    var auth = results.Where(x => x.hints.Count > 0 && PrivateCustomerCheck.Suggest(x.hints) == CustomerType.Authority).ToList();
    var comp = results.Where(x => x.hints.Count > 0 && PrivateCustomerCheck.Suggest(x.hints) == CustomerType.Company).ToList();
    var none = results.Where(x => x.hints.Count == 0).ToList();
    Console.WriteLine($"== {g.Key}: {g.Count()} Kunden – Vorschlag Behörde {auth.Count} ({100.0 * auth.Count / g.Count():0.0} %), Firma {comp.Count} ({100.0 * comp.Count / g.Count():0.0} %), kein Treffer {none.Count}");
    void Show(string title, IEnumerable<((string Kunnr, string Brsch, string N1, string N2, string N3) r, List<CompanyHint> hints)> list)
    {
        Console.WriteLine($"   -- {title}");
        foreach (var (r, h) in list.Take(samples))
            Console.WriteLine($"      {r.Brsch} {r.N1} | {r.N2} | {r.N3}   [{PrivateCustomerCheck.Describe(h)}]");
    }
    if (g.Key.StartsWith("Behörde")) { Show("Behörde ohne Treffer", none.Select(x => x)); Show("als Firma erkannt", comp); }
    else Show("als Behörde erkannt", auth);
    // Gegenrichtung (21.10.2026): als Behörde angelegt – würde gewarnt (Firmenmerkmal)?
    var asAuthority = g.Select(r => (r, hints: PrivateCustomerCheck.Check(new CustomerRegistrationModel
        { CustomerType = CustomerType.Authority, CompanyName = r.N1, CompanyName2 = r.N2, CompanyName3 = r.N3 }))).Where(x => x.hints.Count > 0).ToList();
    Console.WriteLine($"   als Behörde angelegt → Warnung bei {asAuthority.Count} ({100.0 * asAuthority.Count / g.Count():0.0} %)");
    if (g.Key.StartsWith("Behörde")) Show("Behörde, aber Warnung", asAuthority);
}
