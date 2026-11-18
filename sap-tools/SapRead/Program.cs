// Nur lesender SAP-Zugriff (RFC_READ_TABLE, RFC_READ_REPORT). Keine schreibenden Bausteine verwenden.
// Zugangsdaten kommen zur Laufzeit aus dem Key Vault (common/SapSecrets.cs) und werden nicht gespeichert.
//
//   SAPSYS=MEQ|MEP|HCM dotnet run -- table <TABELLE> "<WHERE>" [FELD ...]   (HCM = HR-System 172.20.22.41, Instanz 2)
//   SAPSYS=MEQ|MEP dotnet run -- source <REPORT/INCLUDE> [...]   -> ../abap/<SYS>/<NAME>.abap
using System.Text.Json;
using System.Runtime.InteropServices;
using ERPConnect;

// NW-RFC-Bibliothek aus dem Ausgabeordner laden (aus SAPData/Libs/MacOS kopiert)
NativeLibrary.SetDllImportResolver(typeof(R3Connection).Assembly, (name, _, _) =>
    name.Contains("sapnwrfc") ? NativeLibrary.Load(Path.Combine(AppContext.BaseDirectory, "libsapnwrfc.dylib")) : IntPtr.Zero);

var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../"));
var cfgPath = Path.Combine(root, "../../Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json");
using var cfg = JsonDocument.Parse(File.ReadAllText(cfgPath));
var cred = cfg.RootElement.GetProperty("Sap").GetProperty("Credentials");
LIC.SetLic(SapSecrets.License);

var sys = Environment.GetEnvironmentVariable("SAPSYS") switch { "MEP" => "MEP", "HCM" => "HCM", _ => "MEQ" };
var (host, instance) = sys switch { "MEP" => ("172.20.22.52", 0), "HCM" => ("172.20.22.41", 2), _ => ("172.20.22.50", 0) };
using var con = new R3Connection(host, instance,
    SapSecrets.Rfc.User, SapSecrets.Rfc.Password,
    cred.GetProperty("Language").GetString(), SapSecrets.Rfc.Client)
{ UsesLoadBalancing = false };
con.Open();
Console.WriteLine("verbunden mit " + sys);

switch (args.ElementAtOrDefault(0))
{
    case "table": ReadTable(args[1], args.ElementAtOrDefault(2) ?? "", args.Skip(3).ToArray()); break;
    // Tabellen mit STRING/RAWSTRING-Feldern (RFC_READ_TABLE bricht mit ASSIGN_CASTING_ILLEGAL_CAST ab), z. B. SRT_UTIL_ERRLOG
    // Webservice-Fehlerprotokoll (SRT_UTIL) zu einer Transaktions-ID aus dem SOAP-Fault, z. B. Neukundenanlage
    case "srtlog": ReadSrtLog(args[1]); break;
    case "table2": ReadTable2(args[1], args.ElementAtOrDefault(2) ?? "", args.Skip(3).ToArray()); break;
    case "source": foreach (var n in args.Skip(1)) ReadSource(n); break;
    case "joblog": ReadJobLog(args[1], args[2]); break;
    // Spoolliste eines Jobs (Ausgabe des Reports, z. B. Fehlerliste der Buchhaltungsübergabe) über XBP
    case "spool": ReadJobSpool(args[1], args[2], args.ElementAtOrDefault(3) ?? "1"); break;
    default: Console.WriteLine("Aufruf: table <TAB> \"<WHERE>\" [FELDER] | source <NAME> ..."); break;
}

void ReadTable(string table, string where, string[] fields)
{
    var f = con.CreateFunction("RFC_READ_TABLE");
    f.Exports["QUERY_TABLE"].ParamValue = table;
    f.Exports["DELIMITER"].ParamValue = "|";
    foreach (var fld in fields) f.Tables["FIELDS"].AddRow()["FIELDNAME"] = fld;
    // WHERE in 72-Zeichen-Zeilen, nur an Leerzeichen trennen
    var line = "";
    foreach (var w in where.Split(' ', StringSplitOptions.RemoveEmptyEntries))
    {
        if (line.Length + w.Length + 1 > 72) { f.Tables["OPTIONS"].AddRow()["TEXT"] = line; line = ""; }
        line = line.Length == 0 ? w : line + " " + w;
    }
    if (line.Length > 0) f.Tables["OPTIONS"].AddRow()["TEXT"] = line;
    f.Execute();
    var data = f.Tables["DATA"];
    Console.WriteLine($"-- {table}: {data.RowCount}");
    for (var i = 0; i < data.RowCount; i++)
        Console.WriteLine("   " + string.Join(" | ", data.Rows[i]["WA"].ToString()!.Split('|').Select(s => s.Trim())));
}

void ReadSrtLog(string transactionId)
{
    var f = con.CreateFunction("SRTUTIL_LOG_GET_RESULT");
    f.Exports["TRANSACTION_ID"].ParamValue = transactionId;
    f.Execute();
    var msg = f.Imports["ERROR_MESSAGE"].ParamValue?.ToString();
    if (!string.IsNullOrWhiteSpace(msg)) Console.WriteLine($"-- ERROR_MESSAGE: {msg}");
    var t = f.Imports["RESULT_LIST"].ToTable();
    Console.WriteLine($"-- SRT-Fehlerprotokoll {transactionId}: {t.RowCount}");
    for (var i = 0; i < t.RowCount; i++)
    {
        Console.WriteLine($"   [{i}]");
        foreach (RFCTableColumn c in t.Columns)
        {
            object? v;
            try { v = t.Rows[i][c.Name]; } catch { continue; }
            var text = v is byte[] b ? (b.Length > 0 ? $"<{b.Length} Bytes>" : "") : v?.ToString()?.Trim();
            // Binärfelder (ERROR_CONTEXT, CALLSTACK, PAYLOAD …) zum Auswerten ablegen
            if (v is byte[] { Length: > 0 } raw && Environment.GetEnvironmentVariable("SRTLOG_DIR") is { } outDir)
                File.WriteAllBytes(Path.Combine(outDir, $"{transactionId}_{i}_{c.Name}.bin"), raw);
            if (!string.IsNullOrEmpty(text) && text != "0") Console.WriteLine($"      {c.Name} = {text}");
        }
    }
}

void ReadTable2(string table, string where, string[] fields)
{
    // Wie in der sapdata-API (SAPBroker.Industry): ERPConnect.Utils.ReadTable mit /SAPDS/RFC_READ_TABLE2
    var t = new ERPConnect.Utils.ReadTable(con) { TableName = table, WhereClause = where };
    foreach (var fld in fields) t.AddField(fld);
    t.SetCustomFunctionName("/SAPDS/RFC_READ_TABLE2");
    t.Run();
    Console.WriteLine($"-- {table}: {t.Result.Rows.Count}");
    foreach (System.Data.DataRow r in t.Result.Rows)
        Console.WriteLine("   " + string.Join(" | ", r.ItemArray.Select(v => v?.ToString()?.Trim())));
}

// Nur lesend: Jobprotokoll (SM37) über XBP (BP_JOBLOG_READ ist nicht remote-fähig)
void ReadJobLog(string jobName, string jobCount)
{
    var logon = con.CreateFunction("BAPI_XMI_LOGON");
    logon.Exports["EXTCOMPANY"].ParamValue = "MEESENBURG";
    logon.Exports["EXTPRODUCT"].ParamValue = "SAPTOOLS";
    logon.Exports["INTERFACE"].ParamValue = "XBP";
    logon.Exports["VERSION"].ParamValue = "3.0";
    logon.Execute();
    try
    {
        var f = con.CreateFunction("BAPI_XBP_JOB_JOBLOG_READ");
        f.Exports["JOBNAME"].ParamValue = jobName;
        f.Exports["JOBCOUNT"].ParamValue = jobCount;
        f.Exports["EXTERNAL_USER_NAME"].ParamValue = "SAPTOOLS";
        f.Execute();
        var r = f.Imports["RETURN"].ToStructure();
        Console.WriteLine($"-- RETURN {r["TYPE"]} {r["MESSAGE"]}");
        var log = f.Tables["JOB_PROTOCOL"];
        Console.WriteLine($"-- Jobprotokoll {jobName}/{jobCount}: {log.RowCount}");
        for (var i = 0; i < log.RowCount; i++)
            Console.WriteLine("   " + string.Join(" | ", log.Columns.Cast<RFCTableColumn>().Select(c => log.Rows[i][c.Name]?.ToString()?.Trim()).Where(v => !string.IsNullOrEmpty(v))));
    }
    finally
    {
        var off = con.CreateFunction("BAPI_XMI_LOGOFF");
        off.Exports["INTERFACE"].ParamValue = "XBP";
        off.Execute();
    }
}

// Nur lesend: Spoolliste eines Job-Steps über XBP
void ReadJobSpool(string jobName, string jobCount, string step)
{
    var logon = con.CreateFunction("BAPI_XMI_LOGON");
    logon.Exports["EXTCOMPANY"].ParamValue = "MEESENBURG";
    logon.Exports["EXTPRODUCT"].ParamValue = "SAPTOOLS";
    logon.Exports["INTERFACE"].ParamValue = "XBP";
    logon.Exports["VERSION"].ParamValue = "3.0";
    logon.Execute();
    try
    {
        var f = con.CreateFunction("BAPI_XBP_JOB_SPOOLLIST_READ");
        f.Exports["JOBNAME"].ParamValue = jobName;
        f.Exports["JOBCOUNT"].ParamValue = jobCount;
        f.Exports["STEP_NUMBER"].ParamValue = int.Parse(step);
        f.Exports["EXTERNAL_USER_NAME"].ParamValue = "SAPTOOLS";
        f.Execute();
        var r = f.Imports["RETURN"].ToStructure();
        Console.WriteLine($"-- RETURN {r["TYPE"]} {r["MESSAGE"]}");
        var list = f.Tables["SPOOL_LIST"];
        Console.WriteLine($"-- Spool {jobName}/{jobCount} Step {step}: {list.RowCount} Zeilen");
        for (var i = 0; i < list.RowCount; i++)
            Console.WriteLine("   " + list.Rows[i][0]?.ToString()?.TrimEnd());
    }
    finally
    {
        var off = con.CreateFunction("BAPI_XMI_LOGOFF");
        off.Exports["INTERFACE"].ParamValue = "XBP";
        off.Execute();
    }
}

void ReadSource(string name)
{
    // RPY_PROGRAM_READ liefert auch Klassen-Includes; RFC_READ_REPORT bleibt hier leer
    var f = con.CreateFunction("RPY_PROGRAM_READ");
    f.Exports["PROGRAM_NAME"].ParamValue = name;
    f.Exports["WITH_LOWERCASE"].ParamValue = "X";
    f.Exports["WITH_INCLUDELIST"].ParamValue = " ";
    f.Exports["ONLY_SOURCE"].ParamValue = "X";
    try { f.Execute(); }
    catch (Exception e) { Console.WriteLine($"-- {name}: FEHLER {e.Message}"); return; }
    var q = f.Tables["SOURCE_EXTENDED"];
    var dir = Path.Combine(root, "abap", sys);
    Directory.CreateDirectory(dir);
    var lines = Enumerable.Range(0, q.RowCount).Select(i => q.Rows[i]["LINE"].ToString()!.TrimEnd());
    File.WriteAllLines(Path.Combine(dir, name.Replace("/", "#") + ".abap"), lines);
    Console.WriteLine($"-- {name}: {q.RowCount} Zeilen");
}
