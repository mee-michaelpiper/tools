// TLS-Prüfung eines RDP-Servers wie in unseren Diensten: RDP-Aushandlung (X.224 + RDP_NEG_REQ), dann SslStream mit Standardprüfung.
using System.Net.Security; using System.Net.Sockets; using System.Security.Cryptography.X509Certificates;
var host = args[0]; var port = args.Length > 1 ? int.Parse(args[1]) : 3389;
using var tcp = new TcpClient(); await tcp.ConnectAsync(host, port);
var net = tcp.GetStream();
byte[] req = [0x03,0x00,0x00,0x13, 0x0E,0xE0,0x00,0x00,0x00,0x00,0x00, 0x01,0x00,0x08,0x00, 0x03,0x00,0x00,0x00]; // TLS | CredSSP
await net.WriteAsync(req);
var resp = new byte[19]; var n = 0; while (n < 19) { var r = await net.ReadAsync(resp.AsMemory(n)); if (r == 0) break; n += r; }
Console.WriteLine($"RDP-Antwort: Typ 0x{resp[11]:X2}, Protokoll {BitConverter.ToInt32(resp, 15)} (1=TLS, 2=CredSSP; Typ 0x03 = abgelehnt)");
X509Certificate2? seen = null; SslPolicyErrors errs = default; string[] chain = [];
using var ssl = new SslStream(net, false, (_, c, ch, e) =>
{
    seen = new X509Certificate2(c!); errs = e;
    chain = ch!.ChainElements.Select(x => $"{x.Certificate.Subject}" + (x.ChainElementStatus.Length > 0 ? " [" + string.Join(",", x.ChainElementStatus.Select(s => s.Status)) + "]" : "")).ToArray();
    return e == SslPolicyErrors.None;
});
try { await ssl.AuthenticateAsClientAsync(host); Console.WriteLine($"ERGEBNIS: OK – TLS {ssl.SslProtocol}, Zertifikat vertrauenswürdig"); }
catch (Exception ex) { Console.WriteLine($"ERGEBNIS: FEHLER – {ex.GetBaseException().Message} ({errs})"); }
if (seen is not null)
{
    Console.WriteLine($"  Zertifikat: {seen.Subject}\n  Aussteller: {seen.Issuer}\n  Gültig: {seen.NotBefore:dd.MM.yyyy} – {seen.NotAfter:dd.MM.yyyy}");
    Console.WriteLine($"  Namen: {string.Join(", ", seen.Extensions.OfType<X509SubjectAlternativeNameExtension>().SelectMany(e => e.EnumerateDnsNames()))}; passt zu {host}: {seen.MatchesHostname(host)}");
    Console.WriteLine("  Kette: " + string.Join("  →  ", chain));
}
