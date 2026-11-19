// Test SmbFileStream (Worker) gegen die echte Freigabe – schreibt NUR in den MEQ-Testordner SiSe-Test und löscht danach wieder.
// Prüft: alter Weg (ganze Datei in einem WriteFile) scheitert ab > 1 MiB mit „Not enough credits“, neuer Weg (Blöcke) schreibt die Datei vollständig.
// Anlass: Abbruch des Abendexports der Buchhaltungsübergabe 08./18.11.2026 (sise-docs/es/ANALYSE_Buchhaltungsuebergabe_2026-11-18.md).
// Aufruf: SMB_CREDS=$(az keyvault secret show --vault-name kv-meesenburg-prod -n AdminSmbCredentials --query value -o tsv) dotnet run
using System.Text.Json;
using ESDataWorker.Helpers;
using SMBLibrary; using SMBLibrary.Client;

const string Dir = @"Daten\Programme\SAP\MEQ\ES_ERP\Rechnungen\SiSe-Test";
var c = JsonDocument.Parse(Environment.GetEnvironmentVariable("SMB_CREDS")!).RootElement;
string V(string n) => c.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(V("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("keine Verbindung");
if (client.Login(V("Domain"), V("Username"), V("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("Login fehlgeschlagen");
var store = client.TreeConnect(V("Share"), out _);
Console.WriteLine($"MaxWriteSize Server/Client: {client.MaxWriteSize:N0}");
var rnd = new Random(42);
var failures = 0;
try
{
    // alter Weg zum Nachweis
    var big = new byte[3 * 1024 * 1024 + 123]; rnd.NextBytes(big);
    try { WriteOld($@"{Dir}\chunktest_alt.bin", big); Console.WriteLine("ALT 3 MiB: geschrieben (unerwartet)"); }
    catch (Exception ex) { Console.WriteLine($"ALT 3 MiB: {ex.GetType().Name}: {ex.Message} (erwartet)"); }
    TryDelete($@"{Dir}\chunktest_alt.bin");

    // neuer Weg: 50 Dateien unterschiedlicher Größe in EINER Sitzung, inkl. Grenzfälle
    int[] sizes = [0, 1, 61439, 61440, 61441, 1048576, 1048577, 3 * 1024 * 1024 + 123, 8 * 1024 * 1024];
    var all = sizes.Concat(Enumerable.Range(0, 41).Select(_ => rnd.Next(10_000, 2_500_000))).ToList();
    for (var i = 0; i < all.Count; i++)
    {
        var data = new byte[all[i]]; rnd.NextBytes(data);
        var path = $@"{Dir}\chunktest_{i:00}.bin";
        WriteNew(path, data);
        var back = Read(path);
        var ok = back.AsSpan().SequenceEqual(data);
        if (!ok) failures++;
        if (i < sizes.Length || !ok) Console.WriteLine($"NEU {all[i],10:N0} B: {(ok ? "ok" : "FEHLER")}");
        TryDelete(path);
    }
    Console.WriteLine($"NEU: {all.Count} Dateien, {all.Sum(x => (long)x) / 1024 / 1024} MiB in einer Sitzung, Fehler: {failures}");
}
finally { client.Logoff(); client.Disconnect(); }
return failures == 0 ? 0 : 1;

object Create(string path)
{
    var s = store.CreateFile(out var h, out _, path, AccessMask.GENERIC_WRITE | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.None,
        CreateDisposition.FILE_OVERWRITE_IF, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_NONALERT, null);
    if (s != NTStatus.STATUS_SUCCESS) throw new IOException($"{path}: {s}");
    return h;
}
void WriteOld(string path, byte[] data)
{
    var h = Create(path);
    try { var s = store.WriteFile(out _, h, 0, data); if (s != NTStatus.STATUS_SUCCESS) throw new IOException(s.ToString()); }
    finally { store.CloseFile(h); }
}
void WriteNew(string path, byte[] data)
{
    var h = Create(path);
    try { using var stream = new SmbFileStream(store, h); stream.Write(data, 0, data.Length); }
    finally { store.CloseFile(h); }
}
byte[] Read(string path)
{
    store.CreateFile(out var h, out _, path, AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read,
        CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_NONALERT, null);
    using var ms = new MemoryStream(); long off = 0;
    while (store.ReadFile(out var d, h, off, 65536) == NTStatus.STATUS_SUCCESS && d is { Length: > 0 }) { ms.Write(d); off += d.Length; }
    store.CloseFile(h);
    return ms.ToArray();
}
void TryDelete(string path)
{
    if (store.CreateFile(out var h, out _, path, AccessMask.DELETE | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal,
            ShareAccess.Read | ShareAccess.Write | ShareAccess.Delete, CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE, null) != NTStatus.STATUS_SUCCESS) return;
    store.SetFileInformation(h, new FileDispositionInformation { DeletePending = true });
    store.CloseFile(h);
}
