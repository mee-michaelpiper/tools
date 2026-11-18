// NUR MEQ (Testsystem 172.20.22.50): Buchhaltungsübergabe-Report YFI_UEBERGABE_BELEGE_ES2000 mit eigener Variante testen.
//   dotnet run -- variant   → legt Variante „SISE TEST“ an (Pfad /DFS-MEQ/ES_ERP/Rechnungen/SiSe-Test/, echte Buchung)
//   dotnet run -- run       → startet den Report per XBP als Hintergrundjob, wartet und zeigt das Jobprotokoll
// DYLD_LIBRARY_PATH auf das SapRead-Ausgabeverzeichnis setzen (libsapnwrfc).
using System.Text.Json;
using ERPConnect;

const string Host = "172.20.22.50"; // MEQ – bewusst fest, kein Schalter auf MEP
const string Report = "YFI_UEBERGABE_BELEGE_ES2000";
const string Variant = "SISE TEST";
const string TestPath = "/DFS-MEQ/ES_ERP/Rechnungen/SiSe-Test/";

using var cfg = JsonDocument.Parse(File.ReadAllText("/Users/piper/repos/Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json"));
LIC.SetLic(SapSecrets.License);
var c = cfg.RootElement.GetProperty("Sap").GetProperty("Credentials");
using var con = new R3Connection(Host, 0, SapSecrets.Rfc.User, SapSecrets.Rfc.Password, "DE", SapSecrets.Rfc.Client) { UsesLoadBalancing = false };
con.Open();
Console.WriteLine($"verbunden mit {con.SID}");
if (con.SID != "MEQ") throw new Exception("Nicht MEQ – Abbruch.");

switch (args[0])
{
    case "variant":
    {
        var f = con.CreateFunction("RS_CREATE_VARIANT_RFC");
        f.Exports["CURR_REPORT"].ParamValue = Report;
        f.Exports["CURR_VARIANT"].ParamValue = Variant;
        var desc = f.Exports["VARI_DESC"].ToStructure();
        desc["REPORT"] = Report; desc["VARIANT"] = Variant; desc["ENVIRONMNT"] = "A"; // auch im Hintergrund
        var contents = f.Tables["VARI_CONTENTS"];
        foreach (var (name, value) in new[] { ("P_FITYP", "P"), ("P_LOCT", "A"), ("P_PATH", TestPath), ("P_REFPR", "X"), ("P_TEST", "") })
        {
            var r = contents.AddRow(); r["SELNAME"] = name; r["KIND"] = "P"; r["LOW"] = value;
        }
        var text = f.Tables["VARI_TEXT"].AddRow();
        text["LANGU"] = "D"; text["REPORT"] = Report; text["VARIANT"] = Variant; text["VTEXT"] = "SiSe-Portal Test (Unterordner)";
        f.Execute();
        Console.WriteLine($"Variante „{Variant}“ angelegt: {TestPath}");
        break;
    }
    case "run":
    {
        const string ext = "SISEPORTAL", job = "YFI_ES_ERP_BUCHUNGEN_SISETEST";
        var logon = con.CreateFunction("BAPI_XMI_LOGON");
        logon.Exports["EXTCOMPANY"].ParamValue = "MEESENBURG"; logon.Exports["EXTPRODUCT"].ParamValue = "SISEPORTAL";
        logon.Exports["INTERFACE"].ParamValue = "XBP"; logon.Exports["VERSION"].ParamValue = "3.0";
        logon.Execute();
        try
        {
            var open = con.CreateFunction("BAPI_XBP_JOB_OPEN");
            open.Exports["JOBNAME"].ParamValue = job; open.Exports["EXTERNAL_USER_NAME"].ParamValue = ext;
            open.Execute();
            var count = open.Imports["JOBCOUNT"].ParamValue.ToString()!;
            var step = con.CreateFunction("BAPI_XBP_JOB_ADD_ABAP_STEP");
            step.Exports["JOBNAME"].ParamValue = job; step.Exports["JOBCOUNT"].ParamValue = count;
            step.Exports["EXTERNAL_USER_NAME"].ParamValue = ext; step.Exports["ABAP_PROGRAM_NAME"].ParamValue = Report;
            step.Exports["ABAP_VARIANT_NAME"].ParamValue = Variant; step.Exports["SAP_USER_NAME"].ParamValue = "JOBUSER";
            step.Execute();
            Check(step, "Schritt");
            foreach (var name in new[] { "BAPI_XBP_JOB_CLOSE", "BAPI_XBP_JOB_START_IMMEDIATELY" })
            {
                var f = con.CreateFunction(name);
                f.Exports["JOBNAME"].ParamValue = job; f.Exports["JOBCOUNT"].ParamValue = count; f.Exports["EXTERNAL_USER_NAME"].ParamValue = ext;
                f.Execute(); Check(f, name);
            }
            Console.WriteLine($"Job {job} {count} gestartet");
            string status = "";
            for (var i = 0; i < 60 && status is not ("F" or "A"); i++)
            {
                Thread.Sleep(3000);
                var s = con.CreateFunction("BAPI_XBP_JOB_STATUS_GET");
                s.Exports["JOBNAME"].ParamValue = job; s.Exports["JOBCOUNT"].ParamValue = count; s.Exports["EXTERNAL_USER_NAME"].ParamValue = ext;
                s.Execute(); status = s.Imports["STATUS"].ParamValue.ToString()!;
            }
            Console.WriteLine($"Status {status}");
            var log = con.CreateFunction("BAPI_XBP_JOB_JOBLOG_READ");
            log.Exports["JOBNAME"].ParamValue = job; log.Exports["JOBCOUNT"].ParamValue = count; log.Exports["EXTERNAL_USER_NAME"].ParamValue = ext;
            log.Execute();
            var t = log.Tables["JOB_PROTOCOL"];
            for (var i = 0; i < t.RowCount; i++) Console.WriteLine($"  {t.Rows[i]["ENTERTIME"]} {t.Rows[i]["TEXT"]}");
        }
        finally
        {
            var off = con.CreateFunction("BAPI_XMI_LOGOFF"); off.Exports["INTERFACE"].ParamValue = "XBP"; off.Execute();
        }
        break;
    }
}

static void Check(RFCFunction f, string what)
{
    var r = f.Imports["RETURN"].ToStructure();
    if (r["TYPE"].ToString() is "E" or "A") throw new Exception($"{what}: {r["MESSAGE"]}");
}
