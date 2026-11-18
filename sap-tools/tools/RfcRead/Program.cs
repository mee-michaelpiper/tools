// Nur lesend (SAPSYS=MEQ für das Testsystem, sonst MEP): Variante und Verzeichnislisting per RFC (RS_VARIANT_CONTENTS_RFC, EPS2_GET_DIRECTORY_LISTING).
using System.Text.Json;
using ERPConnect;
using var cfg = JsonDocument.Parse(File.ReadAllText("/Users/piper/repos/Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json"));
LIC.SetLic(SapSecrets.License);
var c = cfg.RootElement.GetProperty("Sap").GetProperty("Credentials");
var host = Environment.GetEnvironmentVariable("SAPSYS") == "MEQ" ? "172.20.22.50" : "172.20.22.52"; // Standard MEP
using var con = new R3Connection(host, 0, SapSecrets.Rfc.User, SapSecrets.Rfc.Password, "DE", SapSecrets.Rfc.Client) { UsesLoadBalancing = false };
con.Open();
switch (args[0])
{
    case "variant":
    {
        var f = con.CreateFunction("RS_VARIANT_CONTENTS_RFC");
        f.Exports["REPORT"].ParamValue = args[1];
        f.Exports["VARIANT"].ParamValue = args[2];
        f.Execute();
        var t = f.Tables["VALUTAB"];
        for (int i = 0; i < t.RowCount; i++)
            Console.WriteLine($"{t.Rows[i]["SELNAME"]} {t.Rows[i]["KIND"]} {t.Rows[i]["SIGN"]} {t.Rows[i]["OPTION"]} '{t.Rows[i]["LOW"]}' '{t.Rows[i]["HIGH"]}'");
        break;
    }
    case "dir":
    {
        var f = con.CreateFunction("EPS2_GET_DIRECTORY_LISTING");
        f.Exports["IV_DIR_NAME"].ParamValue = args[1];
        try { f.Execute(); } catch (Exception e) { Console.WriteLine("Fehler: " + e.Message); break; }
        var t = f.Tables["DIR_LIST"];
        for (int i = 0; i < t.RowCount; i++)
            Console.WriteLine($"{t.Rows[i]["NAME"]} | {t.Rows[i]["SIZE"]} | {t.Rows[i]["MTIM"]}");
        break;
    }
}
