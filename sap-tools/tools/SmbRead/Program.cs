// Nur lesend: lädt Dateien aus <Share>\Daten\Programme\SAP\MEP\ES_ERP\Rechnungen\<Unterordner> nach ./out.
// Zugangsdaten aus Umgebungsvariable SMB_CREDS (Key Vault EsErpSmbCredentials), werden nicht ausgegeben.
using System.Text.Json;
using System.Text.RegularExpressions;
using SMBLibrary; using SMBLibrary.Client;
var c = JsonDocument.Parse(Environment.GetEnvironmentVariable("SMB_CREDS")!).RootElement;
string V(string n) => c.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(V("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("keine Verbindung");
if (client.Login(V("Domain"), V("Username"), V("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("Login fehlgeschlagen");
var store = client.TreeConnect(V("Share"), out _);
var dir = @"Daten\Programme\SAP\MEP\ES_ERP\Rechnungen" + (args.Length > 0 && args[0] != "." ? "\\" + args[0] : "");
var outDir = Path.Combine("out", args.Length > 0 ? args[0] : "root"); Directory.CreateDirectory(outDir);
store.CreateFile(out var h, out _, dir, AccessMask.GENERIC_READ, SMBLibrary.FileAttributes.Directory, ShareAccess.Read | ShareAccess.Write, CreateDisposition.FILE_OPEN, CreateOptions.FILE_DIRECTORY_FILE, null);
store.QueryDirectory(out var entries, h, "*", FileInformationClass.FileDirectoryInformation);
store.CloseFile(h);
var rx = new Regex(args.Length > 1 ? args[1] : @"^SAP_Export.*\.csv$", RegexOptions.IgnoreCase);
foreach (var e in entries.Cast<FileDirectoryInformation>().Where(e => rx.IsMatch(e.FileName)))
{
    store.CreateFile(out var fh, out _, dir + "\\" + e.FileName, AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read, CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_NONALERT, null);
    using var ms = new MemoryStream(); long off = 0;
    while (store.ReadFile(out var data, fh, off, 65536) == NTStatus.STATUS_SUCCESS && data.Length > 0) { ms.Write(data); off += data.Length; }
    store.CloseFile(fh);
    File.WriteAllBytes(Path.Combine(outDir, e.FileName), ms.ToArray());
    Console.WriteLine($"{e.FileName} {ms.Length} B {e.LastWriteTime:dd.MM.yyyy HH:mm}");
}
client.Logoff(); client.Disconnect();
