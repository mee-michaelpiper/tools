// Nur lesend: SQL gegen die esERP-Datenbanken (vmsql005\ES2000). Zugang als JSON (KV-Secret esErpSqlReadonly) über stdin:
//   az keyvault secret show --vault-name kv-meesenburg-prod -n esErpSqlReadonly --query value -o tsv | dotnet run --no-build -- "SELECT …"
// Mehrere Abfragen: je Argument eine. Ausgabe: Spaltenköpfe + Zeilen mit „ | “ getrennt. Nur SELECT (Schutz: läuft in einer Transaktion, die zurückgerollt wird).
using System.Text.Json;
using Microsoft.Data.SqlClient;

var cfg = JsonDocument.Parse(Console.In.ReadToEnd()).RootElement;
string S(string n) => cfg.TryGetProperty(n, out var v) ? v.ToString() : "";
var cs = new SqlConnectionStringBuilder
{
    DataSource = S("server"), InitialCatalog = S("database") is { Length: > 0 } db ? db : "master",
    UserID = S("username"), Password = S("password"), ApplicationName = "sap-tools EsSqlRead",
    Encrypt = !cfg.TryGetProperty("encrypt", out var e) || e.GetBoolean(),
    TrustServerCertificate = cfg.TryGetProperty("trustServerCertificate", out var t) && t.GetBoolean(),
    ConnectTimeout = 15, CommandTimeout = 120
};
using var con = new SqlConnection(cs.ConnectionString);
con.Open();
using var tx = con.BeginTransaction(System.Data.IsolationLevel.ReadUncommitted);
foreach (var sql in args)
{
    using var cmd = new SqlCommand(sql, con, tx);
    using var r = cmd.ExecuteReader();
    do
    {
        Console.WriteLine("-- " + string.Join(" | ", Enumerable.Range(0, r.FieldCount).Select(r.GetName)));
        var n = 0;
        while (r.Read()) { n++; Console.WriteLine("   " + string.Join(" | ", Enumerable.Range(0, r.FieldCount).Select(i => r.IsDBNull(i) ? "∅" : Convert.ToString(r.GetValue(i))))); }
        Console.WriteLine($"   ({n} Zeilen)");
    } while (r.NextResult());
}
tx.Rollback();
