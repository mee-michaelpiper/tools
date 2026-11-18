// SCHREIBEND: setzt am Debitor die Klasse DEBITOR (Klassenart 011) mit Merkmal WERBEVERBOT.
// Nur MEQ. Nutzer-Freigabe 2026-10-06: Musterkunden in MEQ mit srvusr01 pflegen.
//   dotnet run -- <J|N> <KUNNR> [...]
// Existiert die Zuordnung schon, wird BAPI_OBJCL_CHANGE verwendet, sonst BAPI_OBJCL_CREATE.
using System.Runtime.InteropServices;
using System.Text.Json;
using ERPConnect;

NativeLibrary.SetDllImportResolver(typeof(R3Connection).Assembly, (name, _, _) =>
    name.Contains("sapnwrfc") ? NativeLibrary.Load(Path.Combine(AppContext.BaseDirectory, "libsapnwrfc.dylib")) : IntPtr.Zero);

var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../"));
using var cfg = JsonDocument.Parse(File.ReadAllText(Path.Combine(root, "../../Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json")));
var cred = cfg.RootElement.GetProperty("Sap").GetProperty("Credentials");
LIC.SetLic(SapSecrets.License);

// bewusst fest auf MEQ
using var con = new R3Connection("172.20.22.50", 0,
    SapSecrets.Rfc.User, SapSecrets.Rfc.Password,
    cred.GetProperty("Language").GetString(), SapSecrets.Rfc.Client)
{ UsesLoadBalancing = false };
con.Open();

var value = args[0];
if (value is not ("J" or "N")) throw new ArgumentException("Wert muss J oder N sein");

foreach (var kunnr in args.Skip(1).Select(k => k.PadLeft(10, '0')))
{
    var exists = con.CreateFunction("BAPI_OBJCL_EXISTENCECHECK");
    exists.Exports["OBJECTKEY"].ParamValue = kunnr;
    exists.Exports["OBJECTTABLE"].ParamValue = "KNA1";
    exists.Exports["CLASSNUM"].ParamValue = "DEBITOR";
    exists.Exports["CLASSTYPE"].ParamValue = "011";
    exists.Execute();
    var assigned = !Messages(exists).Any(m => m[0] is 'E' or 'A');

    var f = con.CreateFunction(assigned ? "BAPI_OBJCL_CHANGE" : "BAPI_OBJCL_CREATE");
    f.Exports[assigned ? "OBJECTKEY" : "OBJECTKEYNEW"].ParamValue = kunnr;
    f.Exports[assigned ? "OBJECTTABLE" : "OBJECTTABLENEW"].ParamValue = "KNA1";
    f.Exports[assigned ? "CLASSNUM" : "CLASSNUMNEW"].ParamValue = "DEBITOR";
    f.Exports[assigned ? "CLASSTYPE" : "CLASSTYPENEW"].ParamValue = "011";
    var row = f.Tables[assigned ? "ALLOCVALUESCHARNEW" : "ALLOCVALUESCHAR"].AddRow();
    row["CHARACT"] = "WERBEVERBOT";
    row["VALUE_CHAR"] = value;
    f.Execute();

    var msgs = Messages(f);
    var ok = !msgs.Any(m => m[0] is 'E' or 'A');
    var end = con.CreateFunction(ok ? "BAPI_TRANSACTION_COMMIT" : "BAPI_TRANSACTION_ROLLBACK");
    if (ok) end.Exports["WAIT"].ParamValue = "X";
    end.Execute();

    Console.WriteLine($"MEQ {kunnr} {(assigned ? "CHANGE" : "CREATE")} {(ok ? "OK" : "FEHLER")} | {string.Join(" | ", msgs)}");
}

static List<string> Messages(RFCFunction f)
{
    var t = f.Tables["RETURN"];
    return Enumerable.Range(0, t.RowCount).Select(i => $"{t.Rows[i]["TYPE"]}: {t.Rows[i]["MESSAGE"]}").ToList();
}
