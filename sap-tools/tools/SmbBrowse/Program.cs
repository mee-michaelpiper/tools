// Nur lesend: Ordner auf der ES-Freigabe auflisten (Name, Größe, Datum), optional passende Dateien nach ./out laden.
// Zugangsdaten aus SMB_CREDS (Key Vault EsErpSmbCredentials), werden nicht ausgegeben.
//   dotnet run -- "Daten\Dienstleister\Skorzak\Rechnungen_ES2000\Upload_fehlerhaft" [Regex] [--download] [--recurse]
using System.Text.Json;
using System.Text.RegularExpressions;
using SMBLibrary; using SMBLibrary.Client;
var c = JsonDocument.Parse(Environment.GetEnvironmentVariable("SMB_CREDS")!).RootElement;
string V(string n) => c.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(V("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("keine Verbindung");
if (client.Login(V("Domain"), V("Username"), V("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("Login fehlgeschlagen");
var store = client.TreeConnect(V("Share"), out _);
var rx = new Regex(args.Length > 1 && !args[1].StartsWith("--") ? args[1] : ".*", RegexOptions.IgnoreCase);
var download = args.Contains("--download"); var recurse = args.Contains("--recurse");
List(args[0], 0);
client.Logoff(); client.Disconnect();

void List(string dir, int depth)
{
    var s = store.CreateFile(out var h, out _, dir, AccessMask.GENERIC_READ, SMBLibrary.FileAttributes.Directory, ShareAccess.Read | ShareAccess.Write, CreateDisposition.FILE_OPEN, CreateOptions.FILE_DIRECTORY_FILE, null);
    if (s != NTStatus.STATUS_SUCCESS) { Console.WriteLine($"{dir}: {s}"); return; }
    store.QueryDirectory(out var entries, h, "*", FileInformationClass.FileDirectoryInformation);
    store.CloseFile(h);
    foreach (var e in entries.Cast<FileDirectoryInformation>().Where(e => e.FileName is not "." and not "..").OrderBy(e => e.LastWriteTime))
    {
        var isDir = (e.FileAttributes & SMBLibrary.FileAttributes.Directory) != 0;
        if (isDir) { Console.WriteLine($"{new string(' ', depth * 2)}[{e.FileName}]"); if (recurse) List(dir + "\\" + e.FileName, depth + 1); continue; }
        if (!rx.IsMatch(e.FileName)) continue;
        Console.WriteLine($"{new string(' ', depth * 2)}{e.FileName}  {e.EndOfFile} B  {e.LastWriteTime:dd.MM.yyyy HH:mm}");
        if (!download) continue;
        store.CreateFile(out var fh, out _, dir + "\\" + e.FileName, AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read, CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_NONALERT, null);
        using var ms = new MemoryStream(); long off = 0;
        while (store.ReadFile(out var data, fh, off, 65536) == NTStatus.STATUS_SUCCESS && data is { Length: > 0 }) { ms.Write(data); off += data.Length; }
        store.CloseFile(fh);
        Directory.CreateDirectory("out"); File.WriteAllBytes(Path.Combine("out", e.FileName), ms.ToArray());
    }
}
