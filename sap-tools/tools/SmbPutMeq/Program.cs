// Schreibt NUR in den MEQ-Übergabeordner (Daten\Programme\SAP\MEQ\…) – für Tests der Buchhaltungsübergabe im Testsystem.
// Zugang aus SMB_CREDS (Key Vault AdminSmbCredentials), wird nicht ausgegeben.
//   dotnet run -- mkdir "Daten\Programme\SAP\MEQ\ES_ERP\Rechnungen\SiSe-Test"
//   dotnet run -- put   "Daten\Programme\SAP\MEQ\ES_ERP\Rechnungen\SiSe-Test" <lokale Datei>
using System.Text.Json;
using SMBLibrary; using SMBLibrary.Client;

const string Allowed = @"Daten\Programme\SAP\MEQ\";
var dir = args[1].TrimEnd('\\');
if (!dir.StartsWith(Allowed, StringComparison.OrdinalIgnoreCase) || dir.Contains(".."))
    throw new Exception($"Nur unter {Allowed} erlaubt.");

var c = JsonDocument.Parse(Environment.GetEnvironmentVariable("SMB_CREDS")!).RootElement;
string V(string n) => c.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(V("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("keine Verbindung");
if (client.Login(V("Domain"), V("Username"), V("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("Login fehlgeschlagen");
var store = client.TreeConnect(V("Share"), out _);
try
{
    if (args[0] == "mkdir")
    {
        var s = store.CreateFile(out var h, out _, dir, AccessMask.GENERIC_READ, SMBLibrary.FileAttributes.Directory,
            ShareAccess.Read | ShareAccess.Write, CreateDisposition.FILE_OPEN_IF, CreateOptions.FILE_DIRECTORY_FILE, null);
        Console.WriteLine($"{dir}: {s}");
        if (s == NTStatus.STATUS_SUCCESS) store.CloseFile(h);
    }
    else if (args[0] == "put")
    {
        var local = args[2];
        var path = $@"{dir}\{Path.GetFileName(local)}";
        var data = File.ReadAllBytes(local);
        // Nicht überschreiben – eine verarbeitete Datei mit gleichem Namen wäre schon gebucht
        var s = store.CreateFile(out var h, out _, path, AccessMask.GENERIC_WRITE | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal,
            ShareAccess.None, CreateDisposition.FILE_CREATE, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_NONALERT, null);
        if (s != NTStatus.STATUS_SUCCESS) throw new Exception($"{path}: {s}");
        try
        {
            for (var offset = 0; offset < data.Length; offset += 60000)
            {
                var chunk = data.AsSpan(offset, Math.Min(60000, data.Length - offset)).ToArray();
                var w = store.WriteFile(out _, h, offset, chunk);
                if (w != NTStatus.STATUS_SUCCESS) throw new Exception($"Schreiben: {w}");
            }
        }
        finally { store.CloseFile(h); }
        Console.WriteLine($"{path}: {data.Length} B geschrieben");
    }
}
finally { store.Disconnect(); client.Logoff(); client.Disconnect(); }
