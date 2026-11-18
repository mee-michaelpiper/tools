// Nur lesend (SAPSYS=MEQ für das Testsystem, sonst MEP): baut die Belege einer SAP_Export-CSV wie YFI_UEBERGABE_BELEGE_ES2000 auf und ruft BAPI_ACC_DOCUMENT_CHECK (bucht nicht).
using System.Globalization;
using System.Text;
using System.Text.Json;
using ERPConnect;
using ERPConnect.Utils;

Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
using var cfg = JsonDocument.Parse(File.ReadAllText("/Users/piper/repos/Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json"));
LIC.SetLic(SapSecrets.License);
var c = cfg.RootElement.GetProperty("Sap").GetProperty("Credentials");
var host = Environment.GetEnvironmentVariable("SAPSYS") == "MEQ" ? "172.20.22.50" : "172.20.22.52"; // Standard MEP
using var con = new R3Connection(host, 0, SapSecrets.Rfc.User, SapSecrets.Rfc.Password, "DE", SapSecrets.Rfc.Client) { UsesLoadBalancing = false };
con.Open();

string Alpha(string v) { v = v.Trim(); return v.Length > 0 && v.All(char.IsAsciiDigit) ? v.PadLeft(10, '0') : v; }
string Date(string d) => d.Length >= 10 ? d.Substring(6, 4) + d.Substring(3, 2) + d.Substring(0, 2) : "";
decimal Amount(string s) { s = s.Trim(); if (s.Length == 0) return 0; return decimal.Parse(s.Replace(".", "").Replace(",", "."), CultureInfo.InvariantCulture); }
int Sign(string bschl) { int b = int.Parse(bschl); return b == 40 || (b >= 1 && b <= 9) || (b >= 21 && b <= 29) ? 1 : -1; }

var taxCache = new Dictionary<string, (string Kschl, decimal Rate)?>();
(string Kschl, decimal Rate)? Tax(string mwskz)
{
    if (taxCache.TryGetValue(mwskz, out var t)) return t;
    var a = new ReadTable(con) { TableName = "A003", WhereClause = $"KAPPL = 'TX' AND ALAND = 'DE' AND MWSKZ = '{mwskz}'" };
    a.SetCustomFunctionName("/SAPDS/RFC_READ_TABLE2"); a.Run();
    (string, decimal)? r = null;
    foreach (System.Data.DataRow row in a.Result.Rows)
    {
        var k = new ReadTable(con) { TableName = "KONP", WhereClause = $"KNUMH = '{row["KNUMH"]}'" };
        k.SetCustomFunctionName("/SAPDS/RFC_READ_TABLE2"); k.Run();
        var kbetr = decimal.Parse(k.Result.Rows[0]["KBETR"].ToString()!.Trim(), CultureInfo.InvariantCulture);
        if (kbetr != 0) { r = (row["KSCHL"].ToString()!.Trim(), kbetr); break; }
    }
    return taxCache[mwskz] = r;
}

foreach (var file in args)
{
    var lines = File.ReadAllLines(file, Encoding.Latin1).Select(l => l.Split(';')).ToList();
    int errDocs = 0, docs = 0;
    for (int i = 0; i < lines.Count; i++)
    {
        var h = lines[i];
        if (h[0] != "K") continue;
        docs++;
        var f = con.CreateFunction("BAPI_ACC_DOCUMENT_CHECK");
        var hd = f.Exports["DOCUMENTHEADER"].ToStructure();
        hd["BUS_ACT"] = "RFBU"; hd["USERNAME"] = "JOBUSER"; hd["HEADER_TXT"] = h[8].Trim(); hd["COMP_CODE"] = h[3].Trim();
        hd["DOC_DATE"] = Date(h[1]); hd["PSTNG_DATE"] = Date(h[4]); hd["DOC_TYPE"] = h[2].Trim(); hd["REF_DOC_NO"] = h[7].Trim().ToUpperInvariant();
        hd["FIS_PERIOD"] = h[5].Trim();
        var currency = h[6].Trim(); var bukrs = h[3].Trim();
        var gl = f.Tables["ACCOUNTGL"]; var ar = f.Tables["ACCOUNTRECEIVABLE"]; var ap = f.Tables["ACCOUNTPAYABLE"];
        var tx = f.Tables["ACCOUNTTAX"]; var ca = f.Tables["CURRENCYAMOUNT"];
        int item = 0;
        for (int j = i + 1; j < lines.Count && lines[j][0] != "K" && lines[j][0].Trim() != ""; j++)
        {
            var p = lines[j]; var bschl = p[0].Trim(); item++;
            int b = int.Parse(bschl);
            RFCStructure acc;
            if (b == 40 || b == 50) { acc = gl.AddRow(); acc["GL_ACCOUNT"] = Alpha(p[1]); acc["COSTCENTER"] = Alpha(p[4]); acc["ORDERID"] = p[5].Trim(); }
            else if (b >= 1 && b <= 19) { acc = ar.AddRow(); acc["CUSTOMER"] = Alpha(p[1]); acc["SP_GL_IND"] = p[2].Trim(); }
            else { acc = ap.AddRow(); acc["VENDOR_NO"] = Alpha(p[1]); acc["SP_GL_IND"] = p[2].Trim(); }
            acc["ITEMNO_ACC"] = item.ToString("D10"); acc["TAX_CODE"] = p[3].Trim(); acc["PROFIT_CTR"] = p[6].Trim();
            acc["ALLOC_NMBR"] = p.Length > 11 ? p[11].Trim() : ""; acc["ITEM_TEXT"] = p.Length > 12 ? p[12].Trim() : "";
            var amt = Amount(p[7]) * Sign(bschl);
            var baseTxt = p.Length > 9 ? p[9].Trim() : "";
            if (baseTxt.Length > 0)
            {
                var bas = Amount(baseTxt) * Sign(bschl);
                var t = Tax(p[3].Trim().Length >= 2 ? p[3].Trim()[..2] : p[3].Trim());
                if (t is null) { var r0 = ca.AddRow(); r0["ITEMNO_ACC"] = item.ToString("D10"); r0["CURRENCY"] = currency; r0["AMT_DOCCUR"] = amt; r0["AMT_BASE"] = bas; continue; }
                var gross = bas + amt;
                var taxAmt = Math.Round(gross * t.Value.Rate / (1000 + t.Value.Rate), 2, MidpointRounding.AwayFromZero);
                var r1 = ca.AddRow(); r1["ITEMNO_ACC"] = item.ToString("D10"); r1["CURRENCY"] = currency; r1["AMT_DOCCUR"] = 0m; r1["AMT_BASE"] = bas;
                item++;
                var r2 = ca.AddRow(); r2["ITEMNO_ACC"] = item.ToString("D10"); r2["CURRENCY"] = currency; r2["AMT_DOCCUR"] = taxAmt; r2["AMT_BASE"] = gross - taxAmt;
                var tr = tx.AddRow(); tr["ITEMNO_ACC"] = item.ToString("D10"); tr["COND_KEY"] = t.Value.Kschl; tr["TAX_CODE"] = p[3].Trim()[..2];
            }
            else { var r = ca.AddRow(); r["ITEMNO_ACC"] = item.ToString("D10"); r["CURRENCY"] = currency; r["AMT_DOCCUR"] = amt; }
        }
        f.Execute();
        var ret = f.Tables["RETURN"];
        var msgs = Enumerable.Range(0, ret.RowCount).Select(k => (Type: ret.Rows[k]["TYPE"].ToString(), Id: $"{ret.Rows[k]["ID"]}/{ret.Rows[k]["NUMBER"]}", Msg: ret.Rows[k]["MESSAGE"].ToString())).ToList();
        if (msgs.Any(m => m.Type is "E" or "A"))
        {
            errDocs++;
            Console.WriteLine($"  Ref {h[7].Trim()} ({h[1]}, Art {h[2]}, Text {h[8].Trim()}):");
            foreach (var m in msgs.Where(m => m.Type != "S")) Console.WriteLine($"     {m.Type} {m.Id} {m.Msg}");
        }
    }
    Console.WriteLine($"{Path.GetFileName(Path.GetDirectoryName(file))}/{Path.GetFileName(file)}: {docs} Belege, {errDocs} mit Fehler");
}
