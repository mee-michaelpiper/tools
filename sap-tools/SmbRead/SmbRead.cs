#:package SMBLibrary@1.5.7.1
#:package PdfPig@0.1.10
// Nur lesend: Ordner auflisten bzw. Dateien herunterladen von der Freigabe aus EsErpSmbCredentials.
// Aufruf: SMB_CREDS=$(az keyvault secret show --vault-name kv-meesenburg-prod -n EsErpSmbCredentials --query value -o tsv) \
//   dotnet run SmbRead.cs -- list "<Ordner>" [Tiefe]   |   get "<Datei>" "<lokaler Zielordner>"
using System.Text.Json;
using SMBLibrary;
using SMBLibrary.Client;

var creds = JsonDocument.Parse(Environment.GetEnvironmentVariable("SMB_CREDS") ?? throw new Exception("SMB_CREDS fehlt")).RootElement;
string P(string n) => creds.EnumerateObject().First(p => p.Name.Equals(n, StringComparison.OrdinalIgnoreCase)).Value.GetString()!;
var client = new SMB2Client();
if (!client.Connect(P("Host"), SMBTransportType.DirectTCPTransport)) throw new Exception("keine Verbindung");
if (client.Login(P("Domain"), P("Username"), P("Password")) != NTStatus.STATUS_SUCCESS) throw new Exception("Login fehlgeschlagen");
var store = client.TreeConnect(P("Share"), out var st);
if (st != NTStatus.STATUS_SUCCESS) throw new Exception("Share: " + st);

List<FileDirectoryInformation> List(string dir)
{
    var s = store.CreateFile(out var h, out _, dir, AccessMask.GENERIC_READ, SMBLibrary.FileAttributes.Directory, ShareAccess.Read | ShareAccess.Write,
        CreateDisposition.FILE_OPEN, CreateOptions.FILE_DIRECTORY_FILE, null);
    if (s != NTStatus.STATUS_SUCCESS) { Console.WriteLine($"!! {dir}: {s}"); return []; }
    store.QueryDirectory(out var entries, h, "*", FileInformationClass.FileDirectoryInformation);
    store.CloseFile(h);
    return entries.Cast<FileDirectoryInformation>().Where(e => e.FileName is not "." and not "..").ToList();
}

void Walk(string dir, int depth, string indent)
{
    var entries = List(dir);
    var files = entries.Where(e => !e.FileAttributes.HasFlag(SMBLibrary.FileAttributes.Directory)).ToList();
    var dirs = entries.Where(e => e.FileAttributes.HasFlag(SMBLibrary.FileAttributes.Directory)).ToList();
    var byExt = files.GroupBy(f => Path.GetExtension(f.FileName).ToLowerInvariant()).Select(g => $"{g.Key}:{g.Count()}");
    var newest = files.Count > 0 ? files.Max(f => f.LastWriteTime).ToString("yyyy-MM-dd HH:mm") : "-";
    var oldest = files.Count > 0 ? files.Min(f => f.LastWriteTime).ToString("yyyy-MM-dd HH:mm") : "-";
    Console.WriteLine($"{indent}{dir}  Dateien={files.Count} ({string.Join(" ", byExt)}) ältest={oldest} neuest={newest} Unterordner={dirs.Count}");
    if (depth <= 0) return;
    foreach (var d in dirs) Walk(dir + "\\" + d.FileName, depth - 1, indent + "  ");
}

void Tree(string dir)
{
    foreach (var e in List(dir))
    {
        var path = dir + "\\" + e.FileName;
        if (e.FileAttributes.HasFlag(SMBLibrary.FileAttributes.Directory)) Tree(path);
        else Console.WriteLine($"{e.LastWriteTime:yyyy-MM-dd HH:mm}\t{e.EndOfFile}\t{path}");
    }
}

byte[] Read(string path)
{
    var s2 = store.CreateFile(out var fh, out _, path, AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read | ShareAccess.Write,
        CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_ALERT, null);
    if (s2 != NTStatus.STATUS_SUCCESS) throw new Exception(path + ": " + s2);
    using var ms = new MemoryStream();
    long off = 0;
    while (true)
    {
        var r = store.ReadFile(out var data, fh, off, 65536);
        if (r != NTStatus.STATUS_SUCCESS && r != NTStatus.STATUS_END_OF_FILE) throw new Exception("read " + r);
        if (data is null || data.Length == 0) break;
        ms.Write(data); off += data.Length;
    }
    store.CloseFile(fh);
    return ms.ToArray();
}

switch (args[0])
{
    case "pdftext":
        using (var pdf = UglyToad.PdfPig.PdfDocument.Open(Read(args[1])))
        {
            var page = pdf.GetPage(1);
            Console.WriteLine($"Seiten={pdf.NumberOfPages} Zeichen={page.Letters.Count} Bilder={page.GetImages().Count()}");
            Console.WriteLine(page.Text.Length > 1500 ? page.Text[..1500] : page.Text);
        }
        break;
    case "pdfnr":
        // Rechnungsnummer(n) aus PDFs lesen (Dateiliste aus args[1], eine Freigabe-Pfad je Zeile)
        foreach (var path in File.ReadAllLines(args[1]).Where(l => l.Trim().Length > 0))
        {
            var bytes = Read(path.Trim());
            using var pdf = UglyToad.PdfPig.PdfDocument.Open(bytes);
            var text = string.Join(" ", pdf.GetPages().Take(2).Select(pg => pg.Text));
            var nrs = System.Text.RegularExpressions.Regex.Matches(text, @"(?i)(?:rechnung|gutschrift)\s*(9\d{8})").Select(m => m.Groups[1].Value).Distinct();
            Console.WriteLine($"{path.Trim()}\t{string.Join(",", nrs)}");
        }
        break;
    case "tree":
        Tree(args[1]);
        break;
    case "list":
        Walk(args[1], args.Length > 2 ? int.Parse(args[2]) : 1, "");
        break;
    case "files":
        foreach (var f in List(args[1]).Where(e => !e.FileAttributes.HasFlag(SMBLibrary.FileAttributes.Directory)).OrderByDescending(e => e.LastWriteTime).Take(args.Length > 2 ? int.Parse(args[2]) : 30))
            Console.WriteLine($"{f.LastWriteTime:yyyy-MM-dd HH:mm}  {f.EndOfFile,10}  {f.FileName}");
        break;
    case "get":
        var s2 = store.CreateFile(out var fh, out _, args[1], AccessMask.GENERIC_READ | AccessMask.SYNCHRONIZE, SMBLibrary.FileAttributes.Normal, ShareAccess.Read | ShareAccess.Write,
            CreateDisposition.FILE_OPEN, CreateOptions.FILE_NON_DIRECTORY_FILE | CreateOptions.FILE_SYNCHRONOUS_IO_ALERT, null);
        if (s2 != NTStatus.STATUS_SUCCESS) throw new Exception(args[1] + ": " + s2);
        using (var ms = new MemoryStream())
        {
            long off = 0;
            while (true)
            {
                var r = store.ReadFile(out var data, fh, off, 65536);
                if (r != NTStatus.STATUS_SUCCESS && r != NTStatus.STATUS_END_OF_FILE) throw new Exception("read " + r);
                if (data is null || data.Length == 0) break;
                ms.Write(data); off += data.Length;
            }
            store.CloseFile(fh);
            Directory.CreateDirectory(args[2]);
            File.WriteAllBytes(Path.Combine(args[2], Path.GetFileName(args[1].Replace('\\', '/'))), ms.ToArray());
            Console.WriteLine($"{args[1]} -> {ms.Length} Bytes");
        }
        break;
}
store.Disconnect();
client.Logoff();
