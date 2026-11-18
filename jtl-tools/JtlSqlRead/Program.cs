// Nur lesend: SQL gegen die JTL-Wawi (eazybusiness, Lese-Login siseshop_reader). Verbindungszeichenfolge über stdin
// (AppHost-User-Secret Parameters:jtl-sql aus Meesenburg.SiseShop.POC), Tunnel localhost,14330 muss stehen – siehe run.sh.
// Mehrere Abfragen: je Argument eine. Ausgabe: Spaltenköpfe + Zeilen mit „ | “ getrennt. Läuft in einer Transaktion, die zurückgerollt wird.
// Keine Kundendaten ausgeben (Namen, Mails, Adressen) – nur Mengen, Strukturen, Nummern.
using Microsoft.Data.SqlClient;

var cs = new SqlConnectionStringBuilder(Console.In.ReadToEnd().Trim())
{
    ApplicationName = "sap-tools JtlSqlRead", ConnectTimeout = 15, CommandTimeout = 120
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
